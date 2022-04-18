class AddHideNewsToUser < ActiveRecord::Migration
  def change
    add_column :users, :hide_news_at, :datetime
  end
end
