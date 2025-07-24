require 'csv'

module Commands
  class ExportDrops

    def self.register(bot)

      bot.register_application_command(:export_drops, 'View all the drops overall') do |cmd|
        bot.application_command(:export_drops) do |event|
          # Get the member who called the command
          member = event.user.on(event.server)

          # Find the role named "Deputy Owners"
          deputy_role = event.server.roles.find { |r| r.name == "Deputy Owners" }
          file_path = "/tmp/drops_#{Time.now.to_i}.csv"

          unless deputy_role.present? && member&.role?(deputy_role)
            Rails.logger.info("User #{event.server.member(event.user.id).display_name} tried to export_drops but lacked the correct role.")
            event.respond(content: "Sorry, you don't have permission to use this command.", ephemeral: true)
            next
          end

          Rails.logger.info("User #{event.server.member(event.user.id).display_name} accessing all drops")

          # Generate the CSV file
          CSV.open(file_path, "wb") do |csv|
            csv << ["ID", "Team", "Item", "Owner", "Reviewed By", "Status", "Image URL", "Created At"]

            Drop.includes(:team, :item).find_each do |drop|
              csv << [
                drop.id,
                drop.team&.name,
                drop.item&.name,
                drop.owner,
                drop.reviewed_by,
                drop.status,
                drop.img_url,
                drop.created_at
              ]
            end
          end

          # Respond with the file
          event.respond(
            content: "Here's your CSV dump of all drops!",
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
