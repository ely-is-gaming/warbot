module Commands
  class UndoRoll
    def self.register(bot)
      bot.register_application_command(:undo_roll, 'Undo the latest roll for your team or by ID.') do |cmd|
        cmd.integer(:id, 'ID of roll to remove if not running the command in the team channel', required: false)
        bot.application_command(:undo_roll) do |event|
          roll_id = event.options["id"]
          deputy_role = event.server.roles.find { |r| r.name == "Deputy Owners" }
          member = event.user.on(event.server)

          unless deputy_role.present? && member&.role?(deputy_role)
            event.respond(content: "Sorry, you don't have permission to use this command.", ephemeral: true)
            return
          end

          dice_roll = roll_id.present? ? DiceRoll.find_by_id(roll_id) : nil

          unless dice_roll.present?
            team = Team.find_by(name: event.channel.name)
            unless team.present?
              event.respond(content: "Team not found. Provide a roll ID or use the team channel.", ephemeral: true)
              return
            end
            dice_roll = DiceRoll.where(team: team).last
            if dice_roll.nil?
              event.respond(content: "No rolls to undo for this team.", ephemeral: true)
              return
            end
          end

          # prompt for confirmation
          msg = event.channel.send_message(
            "Found roll **#{dice_roll.roll}** for team **#{dice_roll.team.name}**. React with ✅ to delete or ❌ to keep it."
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
            Rails.logger.info("#{reaction_event.user.display_name} deleted roll at ID #{dice_roll.id}")

            dice_roll.delete

            # Recalculate current_tile based on remaining rolls
            team = dice_roll.team
            new_tile = DiceRoll.where(team: team).sum(:roll)
            team.current_tile = new_tile
            team.save!

            event.channel.send_message("✅ Roll deleted! Team **#{team.name}** is now on tile **#{team.current_tile}**.")
            when "❌"
              event.channel.send_message("❌ Roll not removed.")
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
