module Commands
  class UpdateDrop

    def self.register(bot)
        bot.register_application_command(:update_drop, 'Update a specific drop by drop ID') do |cmd|
            cmd.integer(:id, 'ID of drop to update', required: true)
            cmd.string(:team, 'update team', required: false)
            cmd.string(:owner, 'update owner', required: false)
            cmd.string(:submitter, 'update submitter', required: false)
            cmd.string(:reviewed_by, 'update reviewed_by', required: false)
            cmd.string(:status, 'update status (approved or denied)', required: false)

            bot.application_command(:update_drop) do |event|

                params = {
                    id: event.options["id"],
                    team: event.options["team"].present? ? Team.find_or_create_by(name: event.options["team"].present?) : nil,
                    owner: event.options["owner"],
                    submitter: event.options["submitter"],
                    reviewed_by: event.options["reviewed_by"],
                    status: event.options["status"].downcase
                }

                # remove nil values!
                params.compact!

                # Get the member who called the command
                member = event.user.on(event.server)

                # Find the role named "Deputy Owners"
                deputy_role = event.server.roles.find { |r| r.name == "Deputy Owners" }

                unless deputy_role.present? && member&.role?(deputy_role)
                    Rails.logger.info("User #{event.server.member(event.user.id).display_name} tried to update drops but lacked the correct role.")
                    event.respond(content: "Sorry, you don't have permission to use this command.", ephemeral: true)
                    next
                end

                err = validate(params)
                if err.present?
                    Rails.logger.info("User #{event.server.member(event.user.id).display_name} tried to update drops but an err occurred: #{err}.")
                    event.respond(content: err, ephemeral: true)
                    next
                end

                begin
                Drop.transaction do
                    drop = Drop.find_by_id(params[:id])
                    if drop.update!(params)
                        Rails.logger.info("User #{event.server.member(event.user.id).display_name} updated drop ID #{params[:id]} with options: #{params}")
                        event.respond(content: "✅ Drop successfully updated, thanks! #{params}", ephemeral: true)
                    end
                end
                rescue => e
                    event.respond(content: "💫 Whoops 💫 An unexpected error occurred. Send this to Ely: #{e.message} for drop ID: #{params[:id]} to have update #{params}", ephemeral: true)
                    Rails.logger.error("Update failed: #{e.message} when updating drop ID #{params[:id]} with #{params}")
                end
            end
        end
    end

    # validates params
    # 
    # id
    # team
    # owner
    # submitter
    # reviewed_by
    # status (approved or denied only)
    def self.validate(params)
        return 'Drop does not exist, please enter a correct drop ID using the corresponding ID from /export_drops' unless Drop.find_by_id(params[:id]).present?
        if params[:status].present?
            return 'Invalid status - must be either \'approved\' or \'denied\'' unless ['approved', 'denied'].include?(params[:status])
        end
    end
  end
end
