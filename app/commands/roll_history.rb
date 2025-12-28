require 'csv'

module Commands
  class RollHistory

    def self.register(bot)

      bot.register_application_command(:roll_history, 'View all team rolls') do |cmd|
        bot.application_command(:roll_history) do |event|
          # Get the member who called the command
          member = event.user.on(event.server)

          # Find the role named "Deputy Owners"
          deputy_role = event.server.roles.find { |r| r.name == "Deputy Owners" }
          file_path = "/tmp/rolls_#{Time.now.to_i}.csv"

          unless deputy_role.present? && member&.role?(deputy_role)
            Rails.logger.info("User #{event.server.member(event.user.id).display_name} tried to view roll history but lacked the correct role.")
            event.respond(content: "Sorry, you don't have permission to use this command.", ephemeral: true)
            next
          end

          Rails.logger.info("User #{event.server.member(event.user.id).display_name} accessing roll history")

          # Generate the CSV file
          CSV.open(file_path, "wb") do |csv|
            csv << ["ID", "Team", "Roll", "Created At"]

            DiceRoll.includes(:team).find_each do |dr|
              csv << [
                dr.id,
                dr.team&.name,
                dr.roll,
                dr.created_at
              ]
            end
          end

          # Respond with the file
          event.respond(
            content: "Here's your CSV dump of all rolls!",
            ephemeral: true
          )

          # Then send the file as a follow-up
          event.channel.send_file(
            File.open(file_path, "r"),
            filename: File.basename(file_path),
            caption: "Here's your CSV export!"
          )

          # Cleanup
          File.delete(file_path) if File.exist?(file_path)
        end
      end
    end
  end
end
