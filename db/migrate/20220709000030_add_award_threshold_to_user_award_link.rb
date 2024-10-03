# typed: false
class AddAwardThresholdToUserAwardLink < ActiveRecord::Migration
  def change
     add_column :award_user_links, :threshold, :integer
  end
end
