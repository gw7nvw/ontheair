class Add < ActiveRecord::Migration
  def change
      add_column :assets, :valid_from, :datetime
      add_column :assets, :valid_to, :datetime
  end
end
