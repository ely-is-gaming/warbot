module DropCommand

  def self.register(bot)
    bot.application_command(:drop, 'Report a drop to gain points for your team') do |event, item_name:|
      user_id = event.user.id
      # Store drop info, waiting for screenshot
      @pending_drops[user_id] = { item_name: item_name, timestamp: Time.now }
      
      event.respond(content: "Got your drop for **#{item_name}**! Please upload a screenshot now.")
    end
  end

  def self.pending_drops
    @pending_drops
  end
end
