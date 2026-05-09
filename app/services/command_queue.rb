require 'json'
require 'securerandom'
require 'redis'

class CommandQueue
  MAX_ATTEMPTS = 3
  RETRY_DELAY_SECONDS = 2
  REDIS_RECONNECT_DELAY_SECONDS = 5
  QUEUE_KEY = 'war_bot:command_queue'
  PROCESSING_KEY = 'war_bot:command_queue:processing'

  PRIVATE_COMMANDS = %i[
    export_drops
    roll_history
    roll_leaderboard
    set_tile
    update_drop
  ].freeze

  class << self
    def install!(bot)
      @bot = bot

      original_application_command = bot.method(:application_command)

      bot.application_command(:name) do |event|
        unless block
          next original_application_command.call(name, attributes)
        end

        CommandQueue.register_handler(name, block)

        original_application_command.call(name, attributes) do |event|
          CommandQueue.enqueue(
            command_name: name,
            event: event,
            ephemeral: CommandQueue.private_command?(name)
          )
        end
      end
    end

    def register_handler(command_name, block)
      handlers[command_name.to_sym] = block
    end

    def enqueue(command_name:, event:, ephemeral:)
      acknowledge(event, ephemeral)

      payload = serialize(command_name, event, ephemeral)
      redis.lpush(QUEUE_KEY, JSON.generate(payload))

      Rails.logger.info("Queued /#{command_name}; queue depth is #{queue_depth}")
    rescue StandardError => e
      Rails.logger.error("Failed to enqueue /#{command_name}: #{e.class}: #{e.message}")
      notify_enqueue_failure(event, e)
    end

    def start(bot = @bot)
      @bot = bot if bot
      return if worker&.alive?

      @worker = Thread.new do
        Thread.current.name = 'command-queue' if Thread.current.respond_to?(:name=)
        Rails.logger.info("Command queue worker started with Redis at #{ENV.fetch('REDIS_URL', 'redis://redis:6379/0')}")
        recover_processing_jobs

        loop do
          begin
            serialized = redis.brpoplpush(QUEUE_KEY, PROCESSING_KEY, timeout: 5)
            next unless serialized

            perform(serialized)
          rescue Redis::BaseError => e
            reconnect_redis(e)
          end
        end
      end
    end

    def private_command?(command_name)
      PRIVATE_COMMANDS.include?(command_name.to_sym)
    end

    def queue_depth
      redis.llen(QUEUE_KEY)
    end

    def redis
      @redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0'))
    end

    def worker
      @worker
    end

    private

    def handlers
      @handlers ||= {}
    end

    def serialize(command_name, event, ephemeral)
      {
        jid: SecureRandom.uuid,
        command_name: command_name.to_s,
        attempts: 0,
        ephemeral: ephemeral,
        interaction: {
          id: event.interaction.id,
          application_id: event.interaction.application_id,
          token: event.interaction.token
        },
        server_id: event.server_id,
        channel_id: event.channel_id,
        channel_name: event.channel&.name,
        user_id: event.user.id,
        options: event.options,
        resolved: {
          attachments: serialize_attachments(event.resolved.attachments)
        }
      }
    end

    def serialize_attachments(attachments)
      attachments.transform_values do |attachment|
        {
          proxy_url: attachment.proxy_url,
          url: attachment.respond_to?(:url) ? attachment.url : nil
        }
      end
    end

    def acknowledge(event, ephemeral)
      event.defer(ephemeral: ephemeral)
    rescue StandardError => e
      Rails.logger.error("Failed to acknowledge queued command: #{e.class}: #{e.message}")
    end

    def notify_enqueue_failure(event, error)
      event.edit_response(content: "Sorry, I could not queue that command: #{error.message}")
    rescue StandardError => e
      Rails.logger.error("Failed to report enqueue failure: #{e.class}: #{e.message}")
    end

    def perform(serialized)
      payload = JSON.parse(serialized)
      payload['attempts'] += 1

      handler = handlers[payload.fetch('command_name').to_sym]
      raise "No handler registered for /#{payload.fetch('command_name')}" unless handler

      wrapped_event = QueuedApplicationCommandEvent.new(payload: payload, bot: @bot)

      Rails.application.executor.wrap do
        ActiveRecord::Base.connection_pool.with_connection do
          Rails.logger.info("Processing /#{payload['command_name']}, attempt #{payload['attempts']}")
          handler.call(wrapped_event)
          wrapped_event.finish!
        end
      end

      remove_from_processing(serialized)
    rescue StandardError => e
      Rails.logger.error(
        "Queued command failed: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
      )

      retry_or_report(serialized, payload, wrapped_event, e)
    end

    def retry_or_report(serialized, payload, wrapped_event, error)
      remove_from_processing(serialized)

      if payload && payload['attempts'] < MAX_ATTEMPTS
        wrapped_event&.retrying!(payload['attempts'] + 1, MAX_ATTEMPTS)
        sleep RETRY_DELAY_SECONDS
        redis.lpush(QUEUE_KEY, JSON.generate(payload))
      else
        wrapped_event&.failed!(error)
      end
    end

    def remove_from_processing(serialized)
      redis.lrem(PROCESSING_KEY, 1, serialized)
    end

    def recover_processing_jobs
      loop do
        serialized = redis.rpoplpush(PROCESSING_KEY, QUEUE_KEY)
        break unless serialized
      end
    rescue Redis::BaseError => e
      Rails.logger.error("Failed to recover processing queue: #{e.class}: #{e.message}")
      reconnect_redis(e)
    end

    def reconnect_redis(error)
      Rails.logger.error(
        "Command queue Redis unavailable at #{ENV.fetch('REDIS_URL', 'redis://redis:6379/0')}: #{error.class}: #{error.message}. Retrying in #{REDIS_RECONNECT_DELAY_SECONDS} seconds."
      )
      @redis&.close
    rescue StandardError
      nil
    ensure
      @redis = nil
      sleep REDIS_RECONNECT_DELAY_SECONDS
    end
  end
end

class QueuedApplicationCommandEvent
  Attachment = Struct.new(:proxy_url, :url, keyword_init: true)
  Resolved = Struct.new(:attachments, keyword_init: true)

  attr_reader :bot

  def initialize(event: nil, payload: nil, bot: nil)
    @event = event
    @payload = payload
    @bot = bot || (event.bot if event&.respond_to?(:bot))
    @responded = false
  end

  def respond(content: nil, tts: nil, embeds: nil, allowed_mentions: nil, flags: 0, ephemeral: nil, wait: false, components: nil, &block)
    edit_response(content: content, embeds: embeds, allowed_mentions: allowed_mentions, components: components, &block)
  end

  def defer(flags: 0, ephemeral: true)
    nil
  end

  def edit_response(content: nil, embeds: nil, allowed_mentions: nil, components: nil)
    @responded = true

    if @event
      @event.edit_response(content: content, embeds: embeds, allowed_mentions: allowed_mentions, components: components)
    else
      Discordrb::API::Interaction.edit_original_interaction_response(
        interaction_token,
        application_id,
        content,
        embeds,
        allowed_mentions,
        components
      )
    end
  end

  def finish!
    return if @responded

    edit_response(content: 'Command processed. Check this channel for the next step.')
  rescue StandardError => e
    Rails.logger.error("Failed to finalize queued command response: #{e.class}: #{e.message}")
  end

  def retrying!(attempt, max_attempts)
    edit_response(content: "That command hit a temporary error. Retrying now (attempt #{attempt}/#{max_attempts}).")
  rescue StandardError => e
    Rails.logger.error("Failed to update queued command retry status: #{e.class}: #{e.message}")
  end

  def failed!(error)
    edit_response(content: "Sorry, that command failed after multiple attempts: #{error.message}")
  rescue StandardError => e
    Rails.logger.error("Failed to update queued command failure status: #{e.class}: #{e.message}")
  end

  def options
    @event&.options || @payload.fetch('options', {})
  end

  def resolved
    return @event.resolved if @event

    attachment_data = @payload.dig('resolved', 'attachments') || {}
    attachments = attachment_data.transform_keys(&:to_i).transform_values do |data|
      Attachment.new(proxy_url: data['proxy_url'], url: data['url'])
    end

    Resolved.new(attachments: attachments)
  end

  def server
    return @event.server if @event
    return @bot.server(server_id) if @bot&.respond_to?(:server)

    @bot&.servers&.[](server_id)
  end

  def server_id
    @event&.server_id || @payload['server_id']
  end

  def channel
    return @event.channel if @event

    channel = @bot.channel(channel_id) if @bot&.respond_to?(:channel)
    channel || FallbackChannel.new(@payload['channel_name'])
  end

  def channel_id
    @event&.channel_id || @payload['channel_id']
  end

  def user
    return @event.user if @event

    user = @bot.user(user_id) if @bot&.respond_to?(:user)
    user || FallbackUser.new(user_id)
  end

  def user_id
    @event&.user&.id || @payload['user_id']
  end

  def command_name
    @event&.command_name || @payload['command_name'].to_sym
  end

  def interaction
    @event&.interaction
  end

  def method_missing(method_name, *args, **kwargs, &block)
    if @event&.respond_to?(method_name)
      @event.public_send(method_name, *args, **kwargs, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    @event&.respond_to?(method_name, include_private) || super
  end

  private

  def interaction_token
    @payload.fetch('interaction').fetch('token')
  end

  def application_id
    @payload.fetch('interaction').fetch('application_id')
  end
end

class FallbackChannel
  attr_reader :name

  def initialize(name)
    @name = name
  end
end

class FallbackUser
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def on(server)
    server&.member(id)
  end
end
