# app/commands/roll_leaderboard.rb
module Commands
  class RollLeaderboard
    def self.register(bot)
      bot.register_application_command(:roll_leaderboard, 'Show all teams and their current tile progress (Deputy Owners only)') do |_cmd|
        bot.application_command(:roll_leaderboard) do |event|
          event.defer(ephemeral: true) # respond privately if unauthorized

          deputy_role = event.server.roles.find { |r| r.name == "Deputy Owners" }
          member = event.user.on(event.server)

          unless deputy_role.present? && member&.role?(deputy_role)
            event.edit_response(content: "❌ You don't have permission to use this command.")
            next
          end

          teams = Team.all.order(current_tile: :desc)
          tiles = Tile.order(:id).to_a

          if teams.empty?
            event.edit_response(content: "No teams found yet.")
            next
          end

          description = teams.map do |team|
            tile = tiles[team.current_tile] || OpenStruct.new(name: "Unknown")
            mystery_flag = team.current_mystery_id ? " 🎲 (Mystery Tile!)" : ""
            "**#{team.name}** — Tile #{team.current_tile}: #{tile.name}#{mystery_flag}"
          end.join("\n")

          embed = {
            title: "🏆 Team Leaderboard",
            description: description,
            color: 0x00bfff,
            timestamp: Time.now.iso8601
          }

          event.edit_response(embeds: [embed])
        end
      end
    end
  end
end
