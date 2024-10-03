# typed: false
class AddCodeToHut < ActiveRecord::Migration
  def change
    add_column :huts, :code, :string
  end
end
