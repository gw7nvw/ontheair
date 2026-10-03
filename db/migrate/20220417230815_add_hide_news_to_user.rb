# typed: false
class AddHideNewsToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :hide_news_at, :datetime
  end
end
