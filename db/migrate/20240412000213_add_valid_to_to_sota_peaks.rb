class AddValidToToSotaPeaks < ActiveRecord::Migration
  def change
    add_column :sota_peaks, :valid_from, :datetime
    add_column :sota_peaks, :valid_to, :datetime
  end
end
