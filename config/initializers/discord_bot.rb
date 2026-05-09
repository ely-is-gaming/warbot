# config/initializers/discord_bot.rb

require Rails.root.join('app/services/discord_bot.rb')

if ENV["START_DISCORD_BOT"] != "false" && !Rails.env.test?
  Thread.new do
    DiscordBot.run
  end
end
