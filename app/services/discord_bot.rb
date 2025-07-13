require 'discordrb'
require 'dotenv/load'
require 'pry'

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
      team = event.channel.name
      drop_name = event.options["drop_name"]
      # username = event.user.username
      username = event.server.member(event.user.id).display_name


      # text = "Received #{event.user.username}, channel name: #{team}, drop: #{event.options["drop_name"]}, img_url: #{image_url}"
      # text = "**#{username}** received **#{drop_name}**!!"

    embed_title = "#{drop_name} received from ##{team}"
    embed_description = "Submitted by **#{username}**"
    embed_color = 0x00bfff
    embed_timestamp = Time.now

    # Respond in current channel
    event.respond(
      embeds: [
        {
          title: "#{embed_title}!",
          description: embed_description,
          image: { url: image_url },
          color: embed_color,
          timestamp: embed_timestamp.iso8601
        }
      ]
    )

    # Also post to review channel
    review_channel = event.bot.channel(WAR_REVIEW_CHANNEL_ID)
    msg = review_channel.send_embed do |embed|
      embed.title = "#{embed_title}! React with ✅ to approve or ❌ to deny."
      embed.description = embed_description
      embed.image = Discordrb::Webhooks::EmbedImage.new(url: image_url)
      embed.color = embed_color
      embed.timestamp = embed_timestamp
    end

    # make it easier for admins to reply
    msg.create_reaction("✅")
    msg.create_reaction("❌")

    # take action on reviews or denials
    handler = bot.add_await!(Discordrb::Events::ReactionAddEvent) do |reaction_event|
    # Only handle reactions to the review message
    next unless reaction_event.message.id == msg.id
    next unless reaction_event.channel.id == WAR_REVIEW_CHANNEL_ID

    # Role check
    member = reaction_event.server.member(reaction_event.user.id)
    deputy_role = reaction_event.server.roles.find { |r| r.name == "Deputy Owners" }

    next unless member.role?(deputy_role)

    # I can't believe I'm making a switch case for an emoji
    emoji = reaction_event.emoji.name

    case emoji
    when "✅"
      review_channel.send_message("✅ #{embed_title} approved by #{reaction_event.user.display_name}!")
      # maybe update DB or add a role or whatever
    when "❌"
      review_channel.send_message("❌ #{embed_title} denied by #{reaction_event.user.display_name}.")
      # trigger rejection logic here
    else 
      next # ignore subsequent reactions after the initial one
    end

    true # resolve the await so we are not awaiting more actions
  end

  end


    # bot.application_command(:hello, 'Say hello') do |event|
    #   user_mention = "<@#{event.user.id}>"
    #   event.respond("Hello #{user_mention}!")
    # end

    bot.run
  end
end
