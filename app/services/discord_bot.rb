require 'discordrb'

require Rails.root.join('app/services/feature_flags.rb')
require Rails.root.join('app/services/command_queue.rb')
require Rails.root.join('app/commands/add_drop.rb')
require Rails.root.join('app/commands/export_drops.rb')
require Rails.root.join('app/commands/update_drop.rb')
require Rails.root.join('app/commands/roll.rb')
require Rails.root.join('app/commands/roll_history.rb')
require Rails.root.join('app/commands/current_tile.rb')
require Rails.root.join('app/commands/set_tile.rb')
require Rails.root.join('app/commands/roll_leaderboard.rb')


class DiscordBot
  TILE_COMMANDS = [
    ::Commands::Roll,
    ::Commands::RollHistory,
    ::Commands::CurrentTile,
    ::Commands::SetTile,
    ::Commands::RollLeaderboard
  ].freeze

  def self.run
    Rails.logger.info("Starting Discord bot for client #{client_id}")

    bot = Discordrb::Commands::CommandBot.new(
      token: bot_token,
      client_id: client_id,
      intents: Discordrb::INTENTS[:guilds] | Discordrb::INTENTS[:guild_messages] | Discordrb::INTENTS[:message_content] # add only those you enabled
    )

    CommandQueue.install!(bot)

    register_commands(bot)

    CommandQueue.start(bot)

    Rails.logger.info("Discord bot registered commands and is connecting to the gateway")
    bot.run unless Rails.env.test?
  rescue StandardError => e
    Rails.logger.error("Discord bot failed to start: #{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}")
    raise
  end

  def self.bot_token
    ENV["DISCORD_BOT_TOKEN"].presence || Rails.application.credentials.dig(:discord, :discord_bot_token)
  end

  def self.client_id
    ENV["DISCORD_CLIENT_ID"].presence || Rails.application.credentials.dig(:discord, :discord_client_id)
  end

  def self.guild_id
    (ENV["DISCORD_GUILD_ID"].presence || Rails.application.credentials.dig(:discord, :guild_id)).to_i
  end

  def self.register_commands(bot)
    ::Commands::AddDrop.register(bot)
    ::Commands::ExportDrops.register(bot)
    ::Commands::UpdateDrop.register(bot)

    if FeatureFlags.tile_mode?
      TILE_COMMANDS.each { |command| command.register(bot) }
    else
      Rails.logger.info("Tile mode is disabled; skipping tile command registration")
    end
  end
end
