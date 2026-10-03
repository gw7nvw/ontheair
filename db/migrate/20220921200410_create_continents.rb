# typed: false
class CreateContinents < ActiveRecord::Migration[5.0]
  def change
    create_table :continents do |t|
      t.string :name
      t.string :code
    end
  end
end
