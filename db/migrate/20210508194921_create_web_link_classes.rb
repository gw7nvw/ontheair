class CreateWebLinkClasses < ActiveRecord::Migration
  def change
    create_table :web_link_classes do |t|
      t.string :name
      t.string :display_name
      t.string :url
     
      t.boolean :is_active 
      t.timestamps
    end
  end
end
