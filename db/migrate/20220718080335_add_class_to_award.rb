# typed: false
class AddClassToAward < ActiveRecord::Migration[5.0]
  def change
    add_column :award_user_links, :award_class, :string
  end
end
