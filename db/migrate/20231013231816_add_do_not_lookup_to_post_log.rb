class AddDoNotLookupToPostLog < ActiveRecord::Migration
  def change
    add_column :logs, :do_not_lookup, :boolean
    add_column :posts, :do_not_lookup, :boolean
  end
end
