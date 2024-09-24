class AddEonToVolcanoes < ActiveRecord::Migration
  def change
    add_column :volcanos, :eon, :string
    add_column :volcanos, :era, :string
    add_column :volcanos, :min_age, :float
    add_column :volcanos, :max_age, :float
    change_column :volcanos, :age, :float
  
  end
end
