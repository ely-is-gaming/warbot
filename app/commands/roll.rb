module Commands
  class Roll
    MAX_ROLL    = 4
    TOTAL_TILES = 34

    def self.register(bot)
      bot.register_application_command(:roll, 'Roll for a new tile to complete!') do |_cmd|
        bot.application_command(:roll) do |event|
          event.defer(ephemeral: false)
          embed_color = 0x00bfff

          # find or create team
          team = Team.find_or_initialize_by(name: event.channel.name)
          unless team.valid?
            Rails.logger.error("Invalid team #{team.name}: #{team.errors.full_messages.join(', ')}")
            next
          end

          team.current_tile ||= 0
          team.save! if team.changed?

          roll = rand(1..MAX_ROLL)
          modifier_applied = 0

          Team.transaction do
            team.lock!

            # create the main dice roll
            DiceRoll.create!(team: team, roll: roll)

            # move forward by dice
            team.current_tile += roll

            # clamp to max tile
            team.current_tile = [team.current_tile, TOTAL_TILES - 1].min

            # resolve landed tile
            tiles = Tile.order(:id).to_a
            landed_tile = tiles[team.current_tile]

            # apply unconditional modifier if present
            if landed_tile.modifier.present? && landed_tile.modifier != 0
              modifier_applied = landed_tile.modifier
              team.current_tile += modifier_applied
              team.current_tile = [[team.current_tile, 0].max, TOTAL_TILES - 1].min

              # log modifier as its own roll
              DiceRoll.create!(team: team, roll: modifier_applied)
            end

            team.save!
          end

          # final tile after any modifier
          tiles = Tile.order(:id).to_a
          final_tile_index = [team.current_tile, TOTAL_TILES - 1].min
          final_tile = tiles[final_tile_index]

          # build embed title and description
          title =
            if team.current_tile >= TOTAL_TILES
              "🎉 CONGRATULATIONS! You reached the final tile!"
            else
              "Next objective: #{final_tile.name}"
            end

          description = "Team **#{team.name}** rolled a **#{roll}**."
          if modifier_applied != 0
            direction = modifier_applied.positive? ? "forward" : "back"
            description += "\n⚠️ **Tile effect:** move #{direction} #{modifier_applied.abs} space#{'s' if modifier_applied.abs != 1}."
          end
          description += "\n📍 Current position: **Tile #{team.current_tile}**"

          embed = {
            title: title,
            description: description,
            color: embed_color,
            image: final_tile.image_path.present? ? { url: final_tile.image_path } : nil,
            timestamp: Time.now.iso8601
          }.compact

          # send embed
          embed_msg = event.edit_response(embeds: [embed])

          # handle conditional modifier (negative with emoji)
          if final_tile.conditional_modifier.present? && final_tile.conditional_modifier < 0
            arrow_msg = event.channel.send_message(
              "This tile has a special effect! React with ⬅️ to move back #{final_tile.conditional_modifier.abs} tile#{'s' if final_tile.conditional_modifier.abs != 1} or complete the tile and continue onwards."
            )
            arrow_msg.create_reaction("⬅️")

            bot.add_await!(Discordrb::Events::ReactionAddEvent) do |reaction_event|
              next unless reaction_event.message.id == arrow_msg.id
              next unless reaction_event.channel.id == event.channel.id
              next unless reaction_event.user.id == event.user.id # only roller can trigger

              # apply conditional modifier
              team.current_tile += final_tile.conditional_modifier
              team.current_tile = [[team.current_tile, 0].max, TOTAL_TILES - 1].min
              team.save!

              reaction_event.channel.send_message(
                "✅ Conditional effect applied! Team **#{team.name}** moved to tile **#{team.current_tile}** (#{Tile.find_by(id: team.current_tile)&.name || 'unknown'})."
              )

              true # resolve await
            end
          end

          Rails.logger.info("Team #{team.name} rolled #{roll}, modifier #{modifier_applied}, now on tile #{team.current_tile}")
        end
      end
    end
  end
end
