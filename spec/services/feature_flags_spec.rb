require 'rails_helper'

RSpec.describe FeatureFlags do
  around do |example|
    previous_tile_mode = ENV["TILE_MODE"]
    ENV.delete("TILE_MODE")

    example.run
  ensure
    if previous_tile_mode.nil?
      ENV.delete("TILE_MODE")
    else
      ENV["TILE_MODE"] = previous_tile_mode
    end
  end

  describe ".tile_mode?" do
    it "is disabled by default" do
      expect(described_class.tile_mode?).to be false
    end

    it "is enabled when TILE_MODE is true" do
      ENV["TILE_MODE"] = "true"

      expect(described_class.tile_mode?).to be true
    end
  end
end
