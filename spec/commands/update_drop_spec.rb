require 'rails_helper'

RSpec.describe Commands::UpdateDrop do
  let(:drop) { FactoryBot.create(:drop, owner: "OldOwner") }

  let(:mock_event) do
    instance_double(
      Discordrb::Events::ApplicationCommandEvent,
      options: {
        "id" => drop.id,
        "drop_name" => "dragon claws",
        "team" => "red-team",
        "owner" => "User1",
        "submitter" => "User2",
        "reviewed_by" => "ModGuy",
        "status" => "approved"
      },
      server: instance_double(Discordrb::Server),
      user: instance_double(Discordrb::User)
    )
  end

  let(:mock_member) { double("member", role?: true, display_name: "CoolDude") }
  let(:mock_role) { double("role", name: "Deputy Owners") }

  before do
    allow(mock_event.user).to receive(:on).with(mock_event.server).and_return(mock_member)
    allow(mock_event.user).to receive(:id).and_return(123)
    allow(mock_event.server).to receive(:roles).and_return([mock_role])
    allow(mock_event.server).to receive(:member).with(mock_event.user.id).and_return(mock_member)
    allow(mock_event).to receive(:respond)
  end

  it "updates a drop and responds with success" do
    # Create the drop ahead of time
    drop_to_update = drop

    expect {
      described_class.call(mock_event)
    }.to change { drop_to_update.reload.owner }.from("OldOwner").to("User1")

    expect(mock_event).to have_received(:respond).with(
      content: /✅ Drop successfully updated/,
      ephemeral: true
    )
  end

  it "rejects user if they don't have the right role" do
    allow(mock_member).to receive(:role?).with(mock_role).and_return(false)

    described_class.call(mock_event)

    expect(mock_event).to have_received(:respond).with(
      content: /don't have permission/,
      ephemeral: true
    )
  end

  it "responds with error for invalid status" do
    mock_event.options["status"] = "maybe?"

    described_class.call(mock_event)

    expect(mock_event).to have_received(:respond).with(
      content: /Invalid status/,
      ephemeral: true
    )
  end

  it "responds with error if drop doesn't exist" do
    mock_event.options["id"] = 9999

    described_class.call(mock_event)

    expect(mock_event).to have_received(:respond).with(
      content: /Drop does not exist/,
      ephemeral: true
    )
  end

  it "logs and responds to unexpected errors" do
    allow(Drop).to receive(:find_by_id).and_raise(StandardError.new("uh oh"))

    expect(Rails.logger).to receive(:error)

    described_class.call(mock_event)
  end
end
