class AddClassToAward < ActiveRecord::Migration
  def change
    add_column :award_user_links, :award_class, :string
  end
end
