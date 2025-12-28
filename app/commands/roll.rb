module Commands
    class Roll
        MAX_ROLL = 4 # max # a user can roll from 1-MAX_ROLL

        def self.register(bot)
            bot.register_application_command(:roll, 'Roll for a new tile to complete!') do |cmd|
                bot.application_command(:roll) do |event|
                    rolled_by = event.server.member(event.user.id).display_name
                    embed_color = 0x00bfff

                    # create team if not exists
                    team = Team.find_or_initialize_by(name: event.channel.name)
                    unless team.valid?
                        puts "Team #{team.name} is not valid due to: #{team.errors.full_messages.join("\n - ")}. Could not save drop"
                        return
                    end

                    team.save

                    # actually roll the dice for the team & save the roll
                    roll = 1 + Random.rand(MAX_ROLL)

                    # save roll
                    saved_roll = DiceRoll.new(team: team, roll: roll)

                    unless saved_roll.valid?
                        puts "Roll #{saved_roll.roll} from team #{saved_roll.team.name} is not valid due to: #{saved_roll.errors.full_messages.join("\n - ")}. Could not save roll"
                        return
                    end

                    saved_roll.save
                    # log
                    event.respond(
                        embeds: [
                            {
                                title: "Team #{team.name} rolled a #{roll}!",
                                description: "Next objective: XYZ",
                                # image: { url: blah },
                                color: embed_color,
                                timestamp: saved_roll.created_at.iso8601
                            }
                        ]
                    )
                    Rails.logger.info("Saved roll - team #{team.name} rolled a #{roll}!")
                end
            end
        end
    end
end