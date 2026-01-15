# app/commands/roll.rb
module Commands
  class Roll
    MAX_ROLL = 4

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

          # load tiles dynamically
          tiles = Tile.order(:id).to_a
          total_tiles = tiles.size
          original_tile_index = team.current_tile

          # --- ROLL ---
          roll = rand(1..MAX_ROLL)
          DiceRoll.create!(team: team, roll: roll)

          # move forward
          from_tile_index = team.current_tile
          team.current_tile += roll
          team.current_tile = [[team.current_tile, 0].max, total_tiles - 1].min
          to_tile_index = team.current_tile

          description = "Team **#{team.name}** rolled a **#{roll}**.\n"
          description += "📍 Current tile: **#{to_tile_index}** (#{tiles[to_tile_index]&.name || 'unknown'})"

          # --- UNCONDITIONAL MODIFIER ---
          landed_tile = tiles[team.current_tile]
          modifier_applied = 0
          if landed_tile.modifier.present? && landed_tile.modifier != 0
            modifier_applied = landed_tile.modifier
            from_tile_index = team.current_tile
            team.current_tile += modifier_applied
            team.current_tile = [[team.current_tile, 0].max, total_tiles - 1].min
            to_tile_index = team.current_tile

            DiceRoll.create!(team: team, roll: modifier_applied)
            direction = modifier_applied.positive? ? "forward" : "back"
            description += "\n⚠️ Tile effect: move #{direction} #{modifier_applied.abs} space#{'s' if modifier_applied.abs != 1}."
            description += "\n📍 Current tile: **#{to_tile_index}** (#{tiles[to_tile_index]&.name || 'unknown'})"
          end

          team.save!

          # --- TITLE ---
          final_tile = tiles[team.current_tile]
          title = if team.current_tile >= total_tiles - 1
                    "🎉 CONGRATULATIONS! You reached the final tile!"
                  else
                    "Next objective: #{final_tile.name}"
                  end

          # --- SEND EMBED ---
          event.edit_response(
            embeds: [
              {
                title: title,
                description: description,
                color: embed_color,
                image: final_tile.image_path.present? ? { url: final_tile.image_path } : nil,
                timestamp: Time.now.iso8601
              }.compact
            ]
          )

          # --- CONDITIONAL MODIFIER ---
          if final_tile.conditional_modifier.present? && final_tile.conditional_modifier < 0
            arrow_msg = event.channel.send_message(
              "This tile has a special effect! React with ⬅️ to move back #{final_tile.conditional_modifier.abs} tile#{'s' if final_tile.conditional_modifier.abs != 1}, or continue without applying it."
            )
            arrow_msg.create_reaction("⬅️")

            bot.add_await!(Discordrb::Events::ReactionAddEvent) do |reaction_event|
              next unless reaction_event.message.id == arrow_msg.id
              next unless reaction_event.channel.id == event.channel.id
              next unless reaction_event.user.id == event.user.id # only roller

              # apply conditional modifier
              from_tile_index = team.current_tile
              team.current_tile += final_tile.conditional_modifier
              team.current_tile = [[team.current_tile, 0].max, total_tiles - 1].min
              to_tile_index = team.current_tile
              team.save!

              reaction_event.channel.send_message(
                "✅ Conditional effect applied!\n📍 Current tile: **#{to_tile_index}** (#{tiles[to_tile_index]&.name || 'unknown'})"
              )

              true
            end
          end

          Rails.logger.info("Team #{team.name} rolled #{roll}, modifier #{modifier_applied}, now on tile #{team.current_tile}")
        end
      end
    end
  end
end
