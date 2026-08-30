module ExportAssets
  require 'csv'
  @queue = :ota_scheduled
  def self.perform
     export_zlota_assets
     export_pnp
  end

  def self.export_zlota_assets
    # Using the optimized subselect query
    sql = <<-SQL
      SELECT id, name, code, ST_X(location) as x, ST_Y(location) as y, asset_type 
      FROM assets 
      WHERE is_active = true 
        AND minor = false 
        AND asset_type IN (SELECT name FROM asset_types WHERE is_zlota = true)
      ORDER BY code ASC
    SQL

    export_to_zlota_csv(sql)
    export_to_zlota_json(sql)
  end

  def self.export_pnp
    puts "SCHED JOB: Exporting SITES"
    dxccs=['ZL','VK']

    # Open the target file stream first
    File.open('public/assets/sites.json', 'wb') do |file|
      # Pass the open file stream handle directly into the method
      Asset.generate_pnp_sites(dxccs, "", file: file)
    end
  end

  private

  def self.export_to_zlota_csv(sql)
    File.open('public/assets/assets.csv', 'wb') do |file|
      header = ['ID', 'Name', 'Code', 'Longitude', 'Latitude', 'Asset Type']
      file.write(CSV.generate_line(header))

      raw_conn = ActiveRecord::Base.connection.raw_connection

      # 2. A transaction block is mandatory for cursor streaming
      ActiveRecord::Base.transaction do
        # 3. Use send_query to pass the SQL statement safely
        raw_conn.send_query(sql)
        
        # 4. Put the connection into single-row streaming mode
        raw_conn.set_single_row_mode
        
        # 5. Extract results line-by-line out of the connection socket stream
        while (res = raw_conn.get_result)
          res.each_row do |row|
            # row is guaranteed to be a raw array: ["123", "Asset", ...]
            file.write(CSV.generate_line(row))
          end
        end
      end
    end
  end

  def self.export_to_zlota_json(sql)
    File.open('public/assets/assets.json', 'w') do |file|
      file.write("[\n")
      is_first = true

      raw_conn = ActiveRecord::Base.connection.raw_connection

      ActiveRecord::Base.transaction do
        raw_conn.send_query(sql)
        raw_conn.set_single_row_mode
        while (res = raw_conn.get_result)
          res.each_row do |row|
  
            if is_first
              is_first = false
            else
              file.write(",\n")
            end
  
            # Construct raw hash directly from array indices to minimize string allocations
            asset_hash = {
              id:          row[0].to_i,
              name:        row[1],
              code:        row[2],
              longitude:   row[3].to_f ? row[3].to_f : nil,
              latitude:    row[4].to_f ? row[4].to_f : nil,
              asset_type:  row[5]
            }
  
            file.write("  " + JSON.fast_generate(asset_hash))
          end
        end
        file.write("\n]\n")
      end
    end
  end
end
