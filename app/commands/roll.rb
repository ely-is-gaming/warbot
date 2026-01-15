module Commands
    class Roll
        MAX_ROLL = 4 # max # a user can roll from 1-MAX_ROLL
        TOTAL_TILES = 34

        def self.register(bot)
            bot.register_application_command(:roll, 'Roll for a new tile to complete!') do |cmd|
                bot.application_command(:roll) do |event|
                    event.defer(ephemeral: false)
                    
                    rolled_by = event.server.member(event.user.id).display_name
                    embed_color = 0x00bfff
                    previous_total = nil
                    roll = nil
                    saved_roll = nil


                    # create team if not exists
                    team = Team.find_or_initialize_by(name: event.channel.name)
                    unless team.valid?
                        puts "Team #{team.name} is not valid due to: #{team.errors.full_messages.join("\n - ")}. Could not save drop"
                        return
                    end

                    team.save

                    Team.transaction do
                        team.lock! # prevent race conditions for teams
                        previous_total = DiceRoll.where(team: team).sum(:roll)

                        # actually roll the dice for the team & save the roll
                        roll = 1 + Random.rand(MAX_ROLL)

                        # save roll
                        saved_roll = DiceRoll.new(team: team, roll: roll)

                        unless saved_roll.valid?
                            puts "Roll #{saved_roll.roll} from team #{saved_roll.team.name} is not valid due to: #{saved_roll.errors.full_messages.join("\n - ")}. Could not save roll"
                            return
                        end

                        saved_roll.save
                    end

                    # determine next objective
                    total_team_rolls = previous_total + roll
                    tiles = Tile.order(:id).to_a
                    tile_index = [total_team_rolls, TOTAL_TILES - 1].min
                    tile = tiles[tile_index]

                    # apply modifier
                    total_team_rolls += tile.modifier

                    if tile.modifier != 0
                        modified_roll = DiceRoll.new(team: team, roll: tile.modifier)

                        unless saved_roll.valid?
                            puts "MODIFIED roll #{saved_roll.roll} from team #{saved_roll.team.name} is not valid due to: #{saved_roll.errors.full_messages.join("\n - ")}. Could not save roll"
                            return
                        end

                        saved_roll.save

                    end
                    
                    objective = tile[:name]
                    
                    title = if total_team_rolls >= TOTAL_TILES
                    "CONGRATULATIONS!! You've reached the end!"
                    else
                    "Next objective: #{objective}"
                    end

                    embed_description = "Team #{team.name} rolled a #{roll}!"
                    image_path = tile[:image_path]

                    event.edit_response(
                        embeds: [
                            {
                                title: title,
                                description: embed_description,
                                color: embed_color,
                                image: { url: image_path },
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