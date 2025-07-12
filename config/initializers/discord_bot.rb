# config/initializers/discord_bot.rb

require Rails.root.join('app/services/discord_bot.rb')

Thread.new do
  DiscordBot.run
end
