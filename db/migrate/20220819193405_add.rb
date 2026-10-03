# typed: false
class Add < ActiveRecord::Migration[5.0]
  def change
      add_column :assets, :valid_from, :datetime
      add_column :assets, :valid_to, :datetime
  end
end
