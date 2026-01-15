module Commands
  class Roll
    MAX_ROLL = 4
    TOTAL_TILES = 34

    def self.register(bot)
      bot.register_application_command(:roll, 'Roll for a new tile to complete!') do |cmd|
        bot.application_command(:roll) do |event|
          event.defer(ephemeral: false)

          embed_color = 0x00bfff
          rolled_by = event.server.member(event.user.id).display_name

          # ── Team setup ─────────────────────────────
          team = Team.find_or_initialize_by(name: event.channel.name)
          unless team.valid?
            puts "Invalid team: #{team.errors.full_messages.join(', ')}"
            return
          end
          team.save!

          previous_total = nil
          roll = nil
          tiles = Tile.order(:id).to_a

          # ── Atomic roll transaction ───────────────
          Team.transaction do
            team.lock!

            previous_total = DiceRoll.where(team: team).sum(:roll)
            roll = rand(1..MAX_ROLL)

            DiceRoll.create!(team: team, roll: roll)
          end

          # ── Position math ──────────────────────────
          base_position = previous_total + roll
          base_position = [[base_position, 0].max, TOTAL_TILES - 1].min
          tile = tiles[base_position]

          # apply always-on modifier
          final_position = base_position + tile.modifier
          final_position = [[final_position, 0].max, TOTAL_TILES - 1].min
          final_tile = tiles[final_position]

          # ── Response embed ─────────────────────────
          title =
            if final_position >= TOTAL_TILES - 1
              "🎉 CONGRATULATIONS!! You've reached the end!"
            else
              "Next objective: #{final_tile.name}"
            end

            description = "Team **#{team.name}** rolled a **#{roll}**!"

            if tile.modifier != 0
            direction = tile.modifier.positive? ? "forward" : "back"
            description += "\n⬅️ **Forced movement:** move #{direction} #{tile.modifier.abs} tiles."
            end

            if tile.conditional_modifier != 0
            description += "\n\nReact with ⬅️ to move back **#{tile.conditional_modifier.abs}** tiles instead."
            end

          response = event.edit_response(
            embeds: [
              {
                title: title,
                description: description,
                color: embed_color,
                image: { url: final_tile.image_path },
                timestamp: Time.now.iso8601
              }
            ]
          )

          # ── Conditional modifier (reaction-based) ──
          if tile.conditional_modifier != 0
            response.create_reaction("⬅️")

            bot.add_await(
              Discordrb::Events::ReactionAddEvent,
              emoji: "⬅️",
              message: response,
              timeout: 300 # optional safety timeout
            ) do |reaction_event|
              next if reaction_event.user.bot_account?

              # apply conditional movement
              DiceRoll.create!(
                team: team,
                roll: tile.conditional_modifier
              )

              new_position = final_position + tile.conditional_modifier
              new_position = [[new_position, 0].max, TOTAL_TILES - 1].min
              new_tile = tiles[new_position]

              reaction_event.channel.send_embed do |e|
                e.title = "⬅️ Modifier Applied!"
                e.description =
                  "Team moved back **#{tile.conditional_modifier.abs}** tiles.\n" \
                  "New objective: **#{new_tile.name}**"
                e.color = 0xffa500
                e.image = Discordrb::Webhooks::EmbedImage.new(url: new_tile.image_path)
              end
            end
          end

          Rails.logger.info("Team #{team.name} rolled #{roll}")
        end
      end
    end
  end
end
