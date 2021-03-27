class CreateTimezones < ActiveRecord::Migration
  def change
    create_table :timezones do |t|
      t.string "name"
      t.string "description"
      t.integer "difference"
      t.timestamps
    end
  end
end
