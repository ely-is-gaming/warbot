# app/commands/current_tile.rb
module Commands
  class CurrentTile
    def self.register(bot)
      bot.register_application_command(:current_tile, 'Check your team\'s current tile') do |_cmd|
        bot.application_command(:current_tile) do |event|
          team = Team.find_by(name: event.channel.name)

          unless team.present?
            event.respond(content: "No team found for this channel.", ephemeral: true)
            next
          end

          tiles = Tile.order(:id).to_a
          total_tiles = tiles.size
          current_tile_index = [[team.current_tile, 0].max, total_tiles - 1].min
          current_tile = tiles[current_tile_index]

          title = if current_tile_index >= total_tiles - 1
                    "🎉 CONGRATULATIONS! You reached the final tile!"
                  else
                    "Current objective: #{current_tile.name}"
                  end

          description = "📍 Current tile: **#{current_tile_index}** (#{current_tile&.name || 'unknown'})"

          event.respond(
            embeds: [
              {
                title: title,
                description: description,
                color: 0x00bfff,
                image: current_tile.image_path.present? ? { url: current_tile.image_path } : nil,
                timestamp: Time.now.iso8601
              }.compact
            ]
          )
        end
      end
    end
  end
end
