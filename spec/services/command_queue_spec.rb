require 'rails_helper'

RSpec.describe CommandQueue do
  describe '.enqueue' do
    it 'persists a serialized command payload to Redis' do
      redis = instance_double(Redis, lpush: 1, llen: 1)
      interaction = double('interaction', id: 100, application_id: 200, token: 'token')
      channel = double('channel', name: 'blue-team')
      user = double('user', id: 300)
      resolved = double('resolved', attachments: {})
      event = instance_double(
        Discordrb::Events::ApplicationCommandEvent,
        defer: nil,
        interaction: interaction,
        server_id: 400,
        channel_id: 500,
        channel: channel,
        user: user,
        options: { 'tile_index' => 3 },
        resolved: resolved
      )

      allow(described_class).to receive(:redis).and_return(redis)

      described_class.enqueue(command_name: :set_tile, event: event, ephemeral: true)

      expect(redis).to have_received(:lpush) do |key, serialized|
        payload = JSON.parse(serialized)

        expect(key).to eq(described_class::QUEUE_KEY)
        expect(payload['command_name']).to eq('set_tile')
        expect(payload['options']).to eq('tile_index' => 3)
        expect(payload['interaction']).to include('id' => 100, 'application_id' => 200, 'token' => 'token')
      end
    end
  end

  describe '.private_command?' do
    it 'keeps admin and export commands private by default' do
      expect(described_class.private_command?(:update_drop)).to be true
      expect(described_class.private_command?(:roll_history)).to be true
    end

    it 'keeps player-facing commands public by default' do
      expect(described_class.private_command?(:roll)).to be false
      expect(described_class.private_command?(:add_drop)).to be false
    end
  end
end

RSpec.describe QueuedApplicationCommandEvent do
  let(:event) { instance_double(Discordrb::Events::ApplicationCommandEvent) }

  before do
    allow(event).to receive(:edit_response)
  end

  it 'turns command responses into edits of the deferred interaction' do
    queued_event = described_class.new(event: event)

    queued_event.respond(content: 'Done', ephemeral: true)

    expect(event).to have_received(:edit_response).with(
      content: 'Done',
      embeds: nil,
      allowed_mentions: nil,
      components: nil
    )
  end

  it 'does not defer a second time inside queued command handlers' do
    queued_event = described_class.new(event: event)

    expect(queued_event.defer(ephemeral: true)).to be_nil
  end

  it 'delegates unknown methods to the original event' do
    channel = double('channel')
    allow(event).to receive(:channel).and_return(channel)

    queued_event = described_class.new(event: event)

    expect(queued_event.channel).to eq(channel)
  end

  it 'rebuilds attachment resolution from persisted payloads' do
    payload = {
      'options' => { 'drop_photo' => '123' },
      'resolved' => {
        'attachments' => {
          '123' => { 'proxy_url' => 'https://cdn.example/drop.png', 'url' => 'https://example/drop.png' }
        }
      }
    }

    queued_event = described_class.new(payload: payload)

    expect(queued_event.resolved.attachments[123].proxy_url).to eq('https://cdn.example/drop.png')
  end
end
