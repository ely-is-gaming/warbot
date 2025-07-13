require 'discordrb'
require 'dotenv/load'
require 'pry'

require_relative '../commands/add_drop'
class DiscordBot
  BOT_TOKEN = ENV['DISCORD_BOT_TOKEN']
  CLIENT_ID = ENV['DISCORD_CLIENT_ID']
  GUILD_ID = ENV['DISCORD_GUILD_ID'].to_i # for guild command registration (dev/testing)
  WAR_REVIEW_CHANNEL_ID = 1393812141311660052

  def self.run
    bot = Discordrb::Commands::CommandBot.new(
      token: BOT_TOKEN,
      client_id: CLIENT_ID,
      # intents: [:server_messages]
      intents: Discordrb::INTENTS[:guilds] | Discordrb::INTENTS[:guild_messages] | Discordrb::INTENTS[:message_content] # add only those you enabled
    )

    # Register each command from its own module
    Commands::AddDropCommand.register(bot)

    bot.run
  end
end
