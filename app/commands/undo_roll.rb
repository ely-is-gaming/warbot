module Commands
  class UndoRoll
    def self.register(bot)
      bot.register_application_command(:undo_roll, "Undo the last roll for your team or by roll ID") do |cmd|
        cmd.integer(:id, "ID of roll to remove if not running in the team channel", required: false)

        bot.application_command(:undo_roll) do |event|
          roll_id = event.options["id"]

          deputy_role = event.server.roles.find { |r| r.name == "Deputy Owners" }
          member = event.user.on(event.server)

          unless deputy_role.present? && member&.role?(deputy_role)
            event.respond(content: "Sorry, you don't have permission to use this command.", ephemeral: true)
            Rails.logger.info("#{member.display_name} tried to undo a roll without permission.")
            next
          end

          dice_roll = roll_id.present? ? DiceRoll.find_by_id(roll_id) : nil

          unless dice_roll
            team = Team.find_by(name: event.channel.name)
            unless team
              event.respond(content: "Team not found. Provide a roll ID or run this command in the team channel.", ephemeral: true)
              next
            end
            dice_roll = DiceRoll.where(team: team).last
            unless dice_roll
              event.respond(content: "No rolls to undo for this team.", ephemeral: true)
              next
            end
          else
            team = dice_roll.team
          end

          msg = event.channel.send_message(
            "Found roll: #{dice_roll.roll} for team #{team.name}. React ✅ to delete or ❌ to keep."
          )
          msg.create_reaction("✅")
          msg.create_reaction("❌")

          bot.add_await!(Discordrb::Events::ReactionAddEvent) do |reaction_event|
            next unless reaction_event.message.id == msg.id
            next unless reaction_event.channel.id == event.channel.id

            r_member = reaction_event.server.member(reaction_event.user.id)
            next unless deputy_role.present? && r_member&.role?(deputy_role)

            case reaction_event.emoji.name
            when "✅"
              Rails.logger.info("#{r_member.display_name} deleted roll #{dice_roll.id} (#{dice_roll.roll})")
              reaction_event.channel.send_message("✅ Roll #{dice_roll.roll} deleted by #{r_member.display_name}!")

              # Save current tile to previous roll's tile, if any
              dice_roll.destroy
              last_roll = DiceRoll.where(team: team).last
              team.current_tile = last_roll ? last_roll.total_after_roll : 0
              team.save
            when "❌"
              reaction_event.channel.send_message("❌ Roll not removed.")
            end

            true # resolves the await
          end
        end
      end
    end
  end
end
