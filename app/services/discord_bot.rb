require 'discordrb'

require Rails.root.join('app/commands/add_drop.rb')
require Rails.root.join('app/commands/export_drops.rb')

class DiscordBot
  BOT_TOKEN  = Rails.application.credentials.dig(:discord, :discord_bot_token)
  CLIENT_ID  = Rails.application.credentials.dig(:discord, :discord_client_id)
  GUILD_ID   = Rails.application.credentials.dig(:discord, :guild_id).to_i

  def self.run
    bot = Discordrb::Commands::CommandBot.new(
      token: BOT_TOKEN,
      client_id: CLIENT_ID,
      intents: Discordrb::INTENTS[:guilds] | Discordrb::INTENTS[:guild_messages] | Discordrb::INTENTS[:message_content] # add only those you enabled
    )

    # Register each command from its own module
    ::Commands::AddDrop.register(bot)
    ::Commands::ExportDrops.register(bot)

    bot.run
  end
end
