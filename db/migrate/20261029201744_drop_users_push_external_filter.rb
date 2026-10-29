class DropUsersPushExternalFilter < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :push_external_filter
  end
end
