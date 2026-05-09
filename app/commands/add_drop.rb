module Commands
  class AddDrop
    def self.register(bot)
      # Slash command used by players when they receive a drop during war.
      bot.register_application_command(:add_drop, 'Record a received drop to earn points for your team') do |cmd|
        cmd.string(:drop_name, 'Name of received drop', required: true)
        cmd.attachment(:drop_photo, 'Photo of received drop', required: true)
        cmd.string(:owner, 'Owner of received drop if different from submitter', required: false)

        bot.application_command(:add_drop) do |event|
          # Discord stores attachment details in the resolved payload; the option value is the attachment id.
          drop_photo_id = event.options["drop_photo"]
          image_url = event.resolved.attachments[drop_photo_id.to_i].proxy_url
          team = event.channel.name
          drop_name = event.options["drop_name"]
          owner = event.options["owner"]
          submitter = event.server.member(event.user.id).display_name

          Rails.logger.info("Received drop #{drop_name} from submitter #{submitter}")

          # Include the owner only when someone submits a drop on another player's behalf.
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

          # Confirm the submission in the team channel before sending it for review.
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

          # Mirror the submission to the review channel so Deputy Owners can approve or deny it.
          review_channel = event.bot.channel(war_review_channel_id)
          msg = review_channel.send_embed do |embed|
            embed.title = "#{embed_title}! React with ✅ to approve or ❌ to deny."
            embed.description = embed_description
            embed.image = Discordrb::Webhooks::EmbedImage.new(url: image_url)
            embed.color = embed_color
            embed.timestamp = embed_timestamp
          end

          # Seed the review message with the only reactions this flow understands.
          msg.create_reaction("✅")
          msg.create_reaction("❌")

          # Wait for the first valid Deputy Owner reaction on this review message.
          handler = bot.add_await!(Discordrb::Events::ReactionAddEvent) do |reaction_event|
          # Ignore reactions from other messages or channels; this await is scoped in code, not by Discord.
          next unless reaction_event.message.id == msg.id
          next unless reaction_event.channel.id == war_review_channel_id

          # Only Deputy Owners can make the approval decision.
          member = reaction_event.server.member(reaction_event.user.id)
          deputy_role = reaction_event.server.roles.find { |r| r.name == "Deputy Owners" }

          next unless deputy_role.present? && member&.role?(deputy_role)

          # The emoji chosen by the reviewer becomes the persisted drop status.
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

            true # Resolve the await so we do not keep listening after a decision.
          end
        end
      end
    end

    def self.save_drop(event, reaction_event, message, owner=nil, approved)
      drop_photo_id = event.options["drop_photo"]
      drop_name = event.options["drop_name"]
      image_url = event.resolved.attachments[drop_photo_id.to_i].proxy_url

      # When no owner is supplied, treat the command submitter as the drop owner.
      submitter = event.server.member(event.user.id).display_name
      owner = submitter unless owner.present?
      
      # Keep team records aligned to the Discord channel names where drops are submitted.
      team = Team.find_or_initialize_by(name: event.channel.name)

      unless team.valid?
        puts "Team #{team.name} is not valid due to: #{team.errors.full_messages.join("\n - ")}. Could not save drop"
        return
      end

      team.save

      # Create a placeholder item until drops can be matched against a managed item list.
      item = Item.find_or_initialize_by(name: drop_name, category: 'unknown', points: 0)
      unless item.valid?
        Rails.logger.error("Item #{item.name} is not valid due to: #{item.errors.full_messages.join("\n - ")}. Could not save drop")
        return
      end

      item.save

      # Store a human-readable review outcome instead of the raw boolean used by the handler.
      status = approved ? 'approved' : 'denied'
      puts "final status: #{status}"

      # Persist the full audit trail for leaderboard scoring and later review.
      drop = Drop.new(item: item, team: team, img_url: image_url, owner: owner, submitter: submitter, reviewed_by: reaction_event.user.display_name, status: status)
      unless drop.valid?
        puts "Drop ID #{drop.id} is not valid due to: #{drop.errors.full_messages.join("\n - ")}. Could not save drop"
        return
      end

      drop.save
      Rails.logger.info("Saved drop: #{drop.item.name} at ID #{drop.id}")
    end

    def self.war_review_channel_id
      (ENV["WAR_REVIEW_CHANNEL_ID"].presence || Rails.application.credentials.dig(:war_review_channel_id)).to_i
    end
  end
end
