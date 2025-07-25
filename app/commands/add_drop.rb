module Commands
  class AddDrop
    WAR_REVIEW_CHANNEL_ID = Rails.application.credentials.dig(:war_review_channel_id)
    MAX_RETRIES = 2

    def self.register(bot)

      bot.register_application_command(:add_drop, 'Record a received drop to earn points for your team') do |cmd|
        cmd.string(:drop_name, 'Name of received drop', required: true)
        cmd.attachment(:drop_photo, 'Photo of received drop', required: true)
        cmd.string(:owner, 'Owner of received drop if different from submitter', required: false)

        bot.application_command(:add_drop) do |event|
          drop_photo_id = event.options["drop_photo"]
          # [46] pry(DiscordBot)> event.resolved.attachments[1393701689034281071].proxy_url
          image_url = event.resolved.attachments[drop_photo_id.to_i].proxy_url
          team = event.channel.name
          drop_name = event.options["drop_name"]
          # username = event.user.username
          owner = event.options["owner"]
          submitter = event.server.member(event.user.id).display_name

          Rails.logger.info("Received drop #{drop_name} from submitter #{submitter}")

          # text = "Received #{event.user.username}, channel name: #{team}, drop: #{event.options["drop_name"]}, img_url: #{image_url}"
          # text = "**#{submitter}** received **#{drop_name}**!!"

          # create optional statement if owner of drop and submitter are different
          dropped_by = " on behalf of #{owner}"
          embed_description = "Submitted by **#{submitter}**"
          embed_description = embed_description + dropped_by if owner.present?

          embed_title = "#{drop_name} received from ##{team}"
          embed_color = 0x00bfff
          embed_timestamp = Time.now

          unless image_url
            puts "[ERROR] Could not resolve image_url from attachment."
            event.respond(content: "❌ Could not load image. Please try again with a valid attachment.")
            next
          end

          tries = 0
          
          # Respond in current channel
          begin
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
          rescue Discordrb::Errors::UnknownError => e
            tries += 1
            if tries <= MAX_RETRIES
              puts "[WARN] Respond failed, retry ##{tries} after 1 sec delay: #{e.message}"
              sleep 1
              retry
            end
          end

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

          next unless deputy_role.present? && member&.role?(deputy_role)

          # I can't believe I'm making a switch case for an emoji
          emoji = reaction_event.emoji.name

          case emoji
            when "✅"
              Rails.logger.info("#{reaction_event.user.display_name} approved #{embed_title}")
              review_channel.send_message("✅ #{embed_title} approved by #{reaction_event.user.display_name}!")
              save_drop(event, reaction_event, msg, owner, true)
            when "❌"
              Rails.logger.info("#{reaction_event.user.display_name} denied #{embed_title}")
              review_channel.send_message("❌ #{embed_title} denied by #{reaction_event.user.display_name}.")
              save_drop(event, reaction_event, msg, owner, false)
            else 
              next # ignore subsequent reactions after the initial one
            end

            true # resolve the await so we are not awaiting more actions
          end
        end
      end
    end

    def self.save_drop(event, reaction_event, message, owner=nil, approved)
      drop_photo_id = event.options["drop_photo"]
      drop_name = event.options["drop_name"]
      image_url = event.resolved.attachments[drop_photo_id.to_i].proxy_url

      # determine who owner is
      # if owner != nil, owner is owner of drop
      # otherwise the submitter is also the owner
      submitter = event.server.member(event.user.id).display_name
      owner = submitter unless owner.present?
      
      # create team if not exists
      team = Team.find_or_initialize_by(name: event.channel.name)

      unless team.valid?
        puts "Team #{team.name} is not valid due to: #{team.errors.full_messages.join("\n - ")}. Could not save drop"
        return
      end

      team.save

      # look-up item (later we will not create the item because it'll be a pre-set list of items)
      item = Item.find_or_initialize_by(name: drop_name, category: 'unknown', points: 0)
      unless item.valid?
        Rails.logger.error("Item #{item.name} is not valid due to: #{item.errors.full_messages.join("\n - ")}. Could not save drop")
        return
      end

      item.save

      # set human-readable status
      status = approved ? 'approved' : 'denied'
      puts "final status: #{status}"

      drop = Drop.new(item: item, team: team, img_url: image_url, owner: owner, submitter: submitter, reviewed_by: reaction_event.user.display_name, status: status)
      unless drop.valid?
        puts "Drop ID #{drop.id} is not valid due to: #{drop.errors.full_messages.join("\n - ")}. Could not save drop"
        return
      end

      drop.save
      Rails.logger.info("Saved drop: #{drop.item.name} at ID #{drop.id}")
    end
  end
end
