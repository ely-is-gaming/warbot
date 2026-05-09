# config/initializers/discord_bot.rb

require Rails.root.join('app/services/discord_bot.rb')

start_discord_bot_env = ENV["START_DISCORD_BOT"]
start_discord_bot = !Rails.env.test? &&
                    start_discord_bot_env != "false" &&
                    (!defined?(Rails::Console) || start_discord_bot_env == "true")

if start_discord_bot
  Thread.new do
    DiscordBot.run
  end
end
