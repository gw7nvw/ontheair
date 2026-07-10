class CreateVkLakes < ActiveRecord::Migration
  def change
    create_table :vk_lakes do |t|

      t.timestamps
    end
  end
end
