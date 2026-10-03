# typed: false
class AddAwardThresholdToUserAwardLink < ActiveRecord::Migration[5.0]
  def change
     add_column :award_user_links, :threshold, :integer
  end
end
