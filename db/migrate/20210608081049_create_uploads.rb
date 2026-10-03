# typed: false
class CreateUploads < ActiveRecord::Migration[5.0]
  def change
    create_table :uploads do |t|
      t.attachment :doc

      t.timestamps
    end
  end
end
