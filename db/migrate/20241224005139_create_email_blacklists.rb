class CreateEmailBlacklists < ActiveRecord::Migration[5.0]
  def change
    create_table :email_blacklists do |t|
      t.string :email_provider
    end
  end
end
