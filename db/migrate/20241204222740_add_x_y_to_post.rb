class AddXYToPost < ActiveRecord::Migration
  def change
        change_table(:posts) do |t|
          t.point :location, :spatial => true, :srid => 4326
          t.string :loc_source
        end

  end
end
