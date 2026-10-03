# typed: false
class AddRegionAwards < ActiveRecord::Migration[5.0]
  def change
     add_column :award_user_links, :award_type, :string
     add_column :award_user_links, :activity_type, :string
     add_column :award_user_links, :linked_id, :integer
  end
end
