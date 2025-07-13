class Item < ApplicationRecord
  belongs_to :completed_set, optional: true
end
