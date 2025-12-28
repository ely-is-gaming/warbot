module Commands
    class UndoRoll
        def self.register(bot)
            bot.register_application_command(:undo_roll, 'If run in the team\'s channel, it will undo the very latest roll. Otherwise, please enter a roll ID.') do |cmd|
                cmd.integer(:id, 'ID of roll to remove if not running the command in the team channel', required: false)    
                bot.application_command(:undo_roll) do |event|
                    roll_id = event.options["id"]
                    deputy_role = event.server.roles.find { |r| r.name == "Deputy Owners" }
                    # Get the member who called the command
                    member = event.user.on(event.server)

                    # don't bother if caller doesn't have correct permissions to run this
                    unless deputy_role.present? && member&.role?(deputy_role)
                        Rails.logger.info("User #{event.server.member(event.user.id).display_name} tried to undo a roll, but lacked the correct role.")
                        event.respond(content: "Sorry, you don't have permission to use this command.", ephemeral: true)
                        return
                    end

                    dice_roll = roll_id.present? ? DiceRoll.find_by_id(roll_id) : nil

                    Rails.logger.info("Found dice roll at ID #{roll_id} Roll: #{dice_roll.roll}") if dice_roll.present?
                    
                    # get the roll - use channel name (as team name) OR prioritize roll_id if that was passed in
                    unless dice_roll.present?
                        team = Team.find_by(name: event.channel.name)

                        unless team.present?
                            Rails.logger.info("User #{event.server.member(event.user.id).display_name} tried to undo a roll, but we couldn't find the team and no roll ID was provided.")
                            event.respond(content: "Sorry, team not found. Please provide a roll ID or run this command from the correct team channel. If you are doing either of those two things and this still happened, please let Ely know.", ephemeral: true)
                            return
                        end

                        # grab most recent roll by team
                        dice_roll = DiceRoll.where(team: team).last

                        if dice_roll.nil?
                            Rails.logger.info("User #{event.server.member(event.user.id).display_name} tried to undo a roll, but we couldn't find any rolls to undo.")
                            event.respond(content: "The team was found, but they have no active rolls. There is no need to undo a roll.", ephemeral: true)
                            return
                        end
                    end

                    # Are you sure you want to remove?
                    msg = event.channel.send_message(
                        "Found drop - roll was #{dice_roll.roll} for team #{dice_roll.team.name}. React with ✅ to delete or ❌ to keep the roll",
                    )
                    msg.create_reaction("✅")
                    msg.create_reaction("❌")

                    handler = bot.add_await!(Discordrb::Events::ReactionAddEvent) do |reaction_event|
                        # Only handle reactions to the last message in this transaction
                        next unless reaction_event.message.id == msg.id
                        next unless reaction_event.channel.id == event.channel.id

                    # Role check
                    member = reaction_event.server.member(reaction_event.user.id)
                    deputy_role = reaction_event.server.roles.find { |r| r.name == "Deputy Owners" }

                    next unless deputy_role.present? && member&.role?(deputy_role)

                    # I can't believe I'm making a switch case for an emoji
                    emoji = reaction_event.emoji.name

                    case emoji
                        when "✅"
                            Rails.logger.info("#{reaction_event.user.display_name} deleted roll at ID #{dice_roll.id}")
                            event.channel.send_message("✅ Roll #{dice_roll.roll} deleted by #{reaction_event.user.display_name}!")
                            dice_roll.delete
                        when "❌"
                            event.channel.send_message("❌ Roll not removed.")
                        else 
                            next # ignore subsequent reactions after the initial one
                        end

                        true # resolve the await so we are not awaiting more actions
                    end
                end
            end
        end
    end
end