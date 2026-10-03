class CreateVkLakes < ActiveRecord::Migration[5.0]
  def change
    create_table :vk_lakes do |t|

      t.timestamps
    end
  end
end
