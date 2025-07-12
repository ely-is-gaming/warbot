require 'discordrb'
require 'dotenv/load'
require 'pry'

class DiscordBot
  BOT_TOKEN = ENV['DISCORD_BOT_TOKEN']
  CLIENT_ID = ENV['DISCORD_CLIENT_ID']
  GUILD_ID = ENV['DISCORD_GUILD_ID'].to_i # for guild command registration (dev/testing)

  def self.run
    bot = Discordrb::Commands::CommandBot.new(
      token: BOT_TOKEN,
      client_id: CLIENT_ID,
      # intents: [:server_messages]
      intents: Discordrb::INTENTS[:guilds] | Discordrb::INTENTS[:guild_messages] | Discordrb::INTENTS[:message_content] # add only those you enabled
    )

    # Register the slash command
    bot.register_application_command(:hello, 'Says hello') do |cmd|
      cmd.string(:text, 'Text to echo back', required: false)
    end

    # Handle the command
    bot.application_command(:hello) do |event|
      text = "Hi there #{event.user.username}, channel ID: #{event.channel_id}, message: #{event.options["text"]}"
      event.respond(content: text)
    end

        # Register the slash command
    bot.register_application_command(:add_drop, 'Record a received drop to earn points for your team') do |cmd|
      cmd.string(:drop_name, 'Name of received drop', required: true)
      cmd.attachment(:drop_photo, 'Photo of received drop', required: true)
    end

    # Handle the command
    bot.application_command(:add_drop) do |event|
      drop_photo_id = event.options["drop_photo"]
      # [46] pry(DiscordBot)> event.resolved.attachments[1393701689034281071].proxy_url
      image_url = event.resolved.attachments[drop_photo_id.to_i].proxy_url
      channel_name = event.channel.name
      text = "Received #{event.user.username}, channel name: #{channel_name}, drop: #{event.options["drop_name"]}, img_url: #{image_url}"
      event.respond(content: text)

      # event.channel.send_embed do |embed|
      #   embed.title = "test"
      #   embed.image = Discordrb::Webhooks::EmbedImage.new(url: 'https://example.com/image.png')
      #   embed.color = 0x00bfff
      # end
    end


    # bot.application_command(:hello, 'Say hello') do |event|
    #   user_mention = "<@#{event.user.id}>"
    #   event.respond("Hello #{user_mention}!")
    # end

    bot.run
  end
end
