module Commands
  class AddDrop
    def self.register(bot)
      register_review_reaction_handler(bot)

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

          PendingDropReview.create!(
            review_message_id: msg.id.to_s,
            review_channel_id: war_review_channel_id.to_s,
            team_name: team,
            drop_name: drop_name,
            image_url: image_url,
            owner: owner,
            submitter: submitter,
            submitter_user_id: event.user.id.to_s
          )
        end
      end
    end

    def self.register_review_reaction_handler(bot)
      @review_reaction_handler_bots ||= {}
      return if @review_reaction_handler_bots[bot.object_id]

      @review_reaction_handler_bots[bot.object_id] = true

      bot.reaction_add do |reaction_event|
        handle_review_reaction(reaction_event)
      end
    end

    def self.handle_review_reaction(reaction_event)
      emoji = reaction_event.emoji.name
      return unless ["✅", "❌"].include?(emoji)

      pending_review = PendingDropReview.pending.find_by(
        review_message_id: reaction_event.message.id.to_s,
        review_channel_id: reaction_event.channel.id.to_s
      )
      return unless pending_review

      member = reaction_event.server.member(reaction_event.user.id)
      deputy_role = reaction_event.server.roles.find { |r| r.name == "Deputy Owners" }
      return unless deputy_role.present? && member&.role?(deputy_role)

      approved = emoji == "✅"
      status = approved ? "approved" : "denied"
      processed = false

      pending_review.with_lock do
        pending_review.reload
        next unless pending_review.pending?

        save_drop_from_review!(pending_review, reaction_event, approved)
        pending_review.update!(
          status: status,
          reviewed_by: reaction_event.user.display_name,
          reviewed_by_user_id: reaction_event.user.id.to_s,
          reviewed_at: Time.current
        )
        processed = true
      end

      return unless processed

      Rails.logger.info("#{reaction_event.user.display_name} #{status} #{pending_review.drop_name} received from ##{pending_review.team_name}")
      reaction_event.channel.send_message("#{approved ? "✅" : "❌"} #{pending_review.drop_name} received from ##{pending_review.team_name} #{status} by #{reaction_event.user.display_name}!")
    end

    def self.save_drop(event, reaction_event, message, owner=nil, approved)
      drop_photo_id = event.options["drop_photo"]
      drop_name = event.options["drop_name"]
      image_url = event.resolved.attachments[drop_photo_id.to_i].proxy_url

      # When no owner is supplied, treat the command submitter as the drop owner.
      submitter = event.server.member(event.user.id).display_name
      owner = submitter unless owner.present?

      save_drop_from_attributes!(
        team_name: event.channel.name,
        drop_name: drop_name,
        image_url: image_url,
        owner: owner,
        submitter: submitter,
        reviewed_by: reaction_event.user.display_name,
        approved: approved
      )
    end

    def self.save_drop_from_review!(pending_review, reaction_event, approved)
      owner = pending_review.owner.presence || pending_review.submitter

      save_drop_from_attributes!(
        team_name: pending_review.team_name,
        drop_name: pending_review.drop_name,
        image_url: pending_review.image_url,
        owner: owner,
        submitter: pending_review.submitter,
        reviewed_by: reaction_event.user.display_name,
        approved: approved
      )
    end

    def self.save_drop_from_attributes!(team_name:, drop_name:, image_url:, owner:, submitter:, reviewed_by:, approved:)
      # Keep team records aligned to the Discord channel names where drops are submitted.
      team = Team.find_or_initialize_by(name: team_name)

      unless team.valid?
        puts "Team #{team.name} is not valid due to: #{team.errors.full_messages.join("\n - ")}. Could not save drop"
        raise ActiveRecord::RecordInvalid, team
      end

      team.save!

      # Create a placeholder item until drops can be matched against a managed item list.
      item = Item.find_or_initialize_by(name: drop_name, category: 'unknown', points: 0)
      unless item.valid?
        Rails.logger.error("Item #{item.name} is not valid due to: #{item.errors.full_messages.join("\n - ")}. Could not save drop")
        raise ActiveRecord::RecordInvalid, item
      end

      item.save!

      # Store a human-readable review outcome instead of the raw boolean used by the handler.
      status = approved ? 'approved' : 'denied'
      puts "final status: #{status}"

      # Persist the full audit trail for leaderboard scoring and later review.
      drop = Drop.new(item: item, team: team, img_url: image_url, owner: owner, submitter: submitter, reviewed_by: reviewed_by, status: status)
      unless drop.valid?
        puts "Drop ID #{drop.id} is not valid due to: #{drop.errors.full_messages.join("\n - ")}. Could not save drop"
        raise ActiveRecord::RecordInvalid, drop
      end

      drop.save!
      Rails.logger.info("Saved drop: #{drop.item.name} at ID #{drop.id}")
      drop
    end

    def self.war_review_channel_id
      (ENV["WAR_REVIEW_CHANNEL_ID"].presence || Rails.application.credentials.dig(:war_review_channel_id)).to_i
    end
  end
end
