# app/commands/set_tile.rb
module Commands
  class SetTile
    def self.register(bot)
      bot.register_application_command(:set_tile, 'Set your team to a specific tile (admin only)') do |cmd|
        cmd.integer(:tile_index, 'Tile number to set the team to', required: true)

        bot.application_command(:set_tile) do |event|
          deputy_role = event.server.roles.find { |r| r.name == "Deputy Owners" }
          member = event.user.on(event.server)

          unless deputy_role.present? && member&.role?(deputy_role)
            event.respond(content: "Sorry, you don't have permission to use this command.", ephemeral: true)
            next
          end

          tile_index = event.options["tile_index"].to_i
          tiles = Tile.order(:id).to_a
          total_tiles = tiles.size

          if tile_index < 0 || tile_index >= total_tiles
            event.respond(content: "Invalid tile index. Must be between 0 and #{total_tiles - 1}.", ephemeral: true)
            next
          end

          tile = tiles[tile_index]
          team = Team.find_or_initialize_by(name: event.channel.name)
          team.current_tile ||= 0
          team.save! if team.new_record?

          # prompt for confirmation
          msg = event.channel.send_message(
            "We are going to set team **#{team.name}** to tile **#{tile_index} - #{tile.name}**.\nIs this correct?"
          )
          msg.create_reaction("✅")
          msg.create_reaction("❌")

          bot.add_await!(Discordrb::Events::ReactionAddEvent) do |reaction_event|
            next unless reaction_event.message.id == msg.id
            next unless reaction_event.user.id == event.user.id
            next unless reaction_event.channel.id == event.channel.id

            member = reaction_event.server.member(reaction_event.user.id)
            next unless deputy_role.present? && member&.role?(deputy_role)

            emoji = reaction_event.emoji.name

            case emoji
            when "✅"
              team.current_tile = tile_index
              team.save!

              title = if tile_index >= total_tiles - 1
                        "🎉 CONGRATULATIONS! You reached the final tile!"
                      else
                        "Next objective: #{tile.name}"
                      end

              description = "📍 Current tile: **#{tile_index}** (#{tile.name})"

              reaction_event.channel.send_message(
                embeds: [
                  {
                    title: title,
                    description: description,
                    color: 0x00bfff,
                    image: tile.image_path.present? ? { url: tile.image_path } : nil,
                    timestamp: Time.now.iso8601
                  }.compact
                ]
              )
            when "❌"
              reaction_event.channel.send_message("❌ Cancelled. Team **#{team.name}** remains on tile #{team.current_tile}.")
            else
              next
            end

            true
          end
        end
      end
    end
  end
end
