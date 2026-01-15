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
            event.edit_response(content: "⚠️ Error with the team data.")
            next
          end
          team.current_tile ||= 0
          team.save! if team.changed?

          roll = rand(1..MAX_ROLL)

          landed_tile = nil
          modifier_applied = 0

          Team.transaction do
            team.lock!

            # record dice roll
            DiceRoll.create!(team: team, roll: roll)

            # move forward
            team.current_tile += roll

            # clamp
            team.current_tile = [team.current_tile, TOTAL_TILES - 1].min

            # resolve tile
            tiles = Tile.order(:id).to_a
            landed_tile = tiles[team.current_tile]

            # apply unconditional modifier
            if landed_tile.modifier.present? && landed_tile.modifier != 0
              modifier_applied = landed_tile.modifier
              team.current_tile += modifier_applied
              team.current_tile = [[team.current_tile, 0].max, TOTAL_TILES - 1].min

              DiceRoll.create!(team: team, roll: modifier_applied)
            end

            team.save!
          end

          final_tile = Tile.order(:id).to_a[team.current_tile]

          # build description
          description = "Team **#{team.name}** rolled a **#{roll}**."
          if modifier_applied != 0
            direction = modifier_applied.positive? ? "forward" : "back"
            description += "\n\n⚠️ Tile effect: move #{direction} #{modifier_applied.abs} tile#{'s' if modifier_applied.abs != 1}."
          end
          description += "\n📍 Current position: **Tile #{team.current_tile}**"

          # handle conditional modifier
          if final_tile.conditional_modifier != 0
            description += "\n⚠️ Conditional effect! React with ⬅️ to move #{final_tile.conditional_modifier.abs} tile#{'s' if final_tile.conditional_modifier.abs != 1} and claim the item."
          end

          title =
            if team.current_tile >= TOTAL_TILES
              "🎉 CONGRATULATIONS! You've reached the end!"
            else
              "Next objective: #{final_tile.name}"
            end

          # send embed
          response = event.edit_response(
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

          Rails.logger.info("Team #{team.name} rolled #{roll}, modifier #{modifier_applied}, now on tile #{team.current_tile}")

          # wait for conditional reaction if present
          if final_tile.conditional_modifier != 0
            handler = bot.add_await!(Discordrb::Events::ReactionAddEvent) do |reaction_event|
              next unless reaction_event.message.id == response.id
              next unless reaction_event.user.id == event.user.id
              next unless reaction_event.emoji.name == "⬅️"

              # apply conditional move
              team.current_tile += final_tile.conditional_modifier
              team.current_tile = [[team.current_tile, 0].max, TOTAL_TILES - 1].min
              team.save!

              DiceRoll.create!(team: team, roll: final_tile.conditional_modifier)

              event.channel.send_message(
                "✅ Conditional move applied! Team **#{team.name}** moved #{final_tile.conditional_modifier} tiles and claimed the item!"
              )
              true
            end
          end
        end
      end
    end
  end
end
