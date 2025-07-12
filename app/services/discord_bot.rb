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
    bot.register_application_command(:hello, 'Says hello')

    # Handle the command
    bot.application_command(:hello) do |event|
      text = "Hi there #{event.user.username}"
      event.respond(content: text)
    end


    # bot.application_command(:hello, 'Say hello') do |event|
    #   user_mention = "<@#{event.user.id}>"
    #   event.respond("Hello #{user_mention}!")
    # end

    bot.run
  end
end
