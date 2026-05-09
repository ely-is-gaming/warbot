require 'rails_helper'

RSpec.describe DiscordBot do
  let(:bot) { double("bot") }

  before do
    allow(Commands::AddDrop).to receive(:register)
    allow(Commands::ExportDrops).to receive(:register)
    allow(Commands::UpdateDrop).to receive(:register)
    allow(Commands::Roll).to receive(:register)
    allow(Commands::RollHistory).to receive(:register)
    allow(Commands::CurrentTile).to receive(:register)
    allow(Commands::SetTile).to receive(:register)
    allow(Commands::RollLeaderboard).to receive(:register)
  end

  describe ".register_commands" do
    it "skips tile commands when tile mode is disabled" do
      allow(FeatureFlags).to receive(:tile_mode?).and_return(false)

      described_class.register_commands(bot)

      expect(Commands::AddDrop).to have_received(:register).with(bot)
      expect(Commands::ExportDrops).to have_received(:register).with(bot)
      expect(Commands::UpdateDrop).to have_received(:register).with(bot)
      expect(Commands::Roll).not_to have_received(:register)
      expect(Commands::RollHistory).not_to have_received(:register)
      expect(Commands::CurrentTile).not_to have_received(:register)
      expect(Commands::SetTile).not_to have_received(:register)
      expect(Commands::RollLeaderboard).not_to have_received(:register)
    end

    it "registers tile commands when tile mode is enabled" do
      allow(FeatureFlags).to receive(:tile_mode?).and_return(true)

      described_class.register_commands(bot)

      expect(Commands::Roll).to have_received(:register).with(bot)
      expect(Commands::RollHistory).to have_received(:register).with(bot)
      expect(Commands::CurrentTile).to have_received(:register).with(bot)
      expect(Commands::SetTile).to have_received(:register).with(bot)
      expect(Commands::RollLeaderboard).to have_received(:register).with(bot)
    end
  end
end
