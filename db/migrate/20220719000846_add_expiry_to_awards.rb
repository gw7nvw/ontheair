# typed: false
class AddExpiryToAwards < ActiveRecord::Migration
  def change
    add_column :award_user_links, :expired_at, :datetime
    add_column :award_user_links, :expired, :boolean
  end
end
