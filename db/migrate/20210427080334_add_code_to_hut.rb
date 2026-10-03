# typed: false
class AddCodeToHut < ActiveRecord::Migration[5.0]
  def change
    add_column :huts, :code, :string
  end
end
