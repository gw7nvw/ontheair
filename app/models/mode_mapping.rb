class ModeMapping < ApplicationRecord
  validates :raw_mode, presence: true, uniqueness: { case_sensitive: false }
  validates :parent_group, presence: true

  before_save :uppercase_fields

  private

  def uppercase_fields
    self.raw_mode = raw_mode.to_s.strip.upcase
    self.parent_group = parent_group.to_s.strip.upcase
  end
end
