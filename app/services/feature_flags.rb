class FeatureFlags
  TRUE_VALUES = %w[1 true t yes y on].freeze

  class << self
    def tile_mode?
      enabled?("TILE_MODE")
    end

    private

    def enabled?(env_name)
      value = ENV.fetch(env_name, "false")
      TRUE_VALUES.include?(value.to_s.downcase)
    end
  end
end
