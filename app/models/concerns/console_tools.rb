module ConsoleTools
  def self.seed_local_map_tiles(tile_server_template, dxcc)
    ActiveRecord::Base.establish_connection :zl_gis
    ActiveRecord::Base.with_connection do |conn|
      start_time = Time.now
      puts "🚀 Starting XYZ Map Tile Seeding for Zoom 9 (VK/ZL Landmasses)..."

      tile_server_template=tile_server_template.gsub("{", "--").gsub("}", "--")

      # Define the precise landmass bounding boxes for Zoom 9
      if dxcc=="VK" then
        regions = [ { name: "Australia",   z: 9, x_range: (416..475), y_range: (270..325) } ]
      elsif dxcc=="ZL" then
        regions = [ { name: "New Zealand", z: 9, x_range: (492..510), y_range: (307..334) } ]
      else
        puts "Unknown region #{dxcc}"
        return
      end

      # Calculate total tiles to download
      total_tiles = regions.sum { |r| r[:x_range].size * r[:y_range].size }
      puts "Total tiles to process: #{total_tiles}"

      # Extract host and base path from your template URL to reuse the HTTP connection
      # e.g., "https://openstreetmap.org{z}/{x}/{y}.png"
      uri_template = URI.parse(tile_server_template)

      processed_count = 0
      inserted_count  = 0

      # Open a single persistent HTTP connection to the tile server
      Net::HTTP.start(uri_template.host, uri_template.port, use_ssl: (uri_template.scheme == "https")) do |http|
        regions.each do |region|
          puts "\n🌍 Processing #{region[:name]}..."
          z = region[:z]

          region[:x_range].each do |x|
            # Array bucket to collect rows for small batch inserts
            batch_rows = []

            region[:y_range].each do |y|
              processed_count += 1

              # Print a progress indicator every 100 tiles
              if processed_count % 100 == 0 || processed_count == total_tiles
                percent = ((processed_count.to_f / total_tiles) * 100).round(1)
                print "\rProgress: #{processed_count}/#{total_tiles} tiles checked (#{percent}%)"
                $stdout.flush
              end

              # 1. Skip if we already have this tile stored in the database
              next if conn.select_value(
                "SELECT 1 FROM local_map_tiles WHERE z = #{z} AND x = #{x} AND y = #{y}"
              )

              # 2. Build the URL path for this specific tile
              path = uri_template.path.gsub("--z--", z.to_s).gsub("--x--", x.to_s).gsub("--y--", y.to_s)
              path += "?#{uri_template.query}" if uri_template.query.present?
              puts "PATH: #{path}"
              # 3. Fetch the raw binary tile asset via HTTP
              response = http.get(path, { "User-Agent" => "ontheair {admin@ontheair.nz}/2.0" })

              if response.code == "200" && response.body.present?
                # Quote and escape the binary string data for a raw PostgreSQL injection
                escaped_hex = PG::Connection.escape_bytea(response.body)

                # 2. Wrap it in single quotes so it compiles perfectly inside the VALUES string
                batch_rows << "(#{z}, #{x}, #{y}, '#{escaped_hex}', NOW(), NOW())"
                inserted_count += 1
                inserted_count += 1
              else
                Rails.logger.warn "\n⚠️ Failed to download tile #{z}/#{x}/#{y} (HTTP #{response.code})"
              end
            end

            # 4. Commit this column batch to the database in a single fast bulk insert query
            if batch_rows.any?
                conn.execute(<<~SQL)
                INSERT INTO local_map_tiles (z, x, y, tile_bytes, created_at, updated_at)
                VALUES #{batch_rows.join(',')}
                ON CONFLICT (z, x, y) DO NOTHING;
              SQL
            end
          end
        end
      end
    end

    #    duration = (Time.now - start_time).round(1)
    puts "\n\n🎉 Seeding Complete!"
    #    puts "⏱️ Time taken: #{duration} seconds"
    puts "💾 New tiles downloaded and saved: #{inserted_count}"
    puts "📚 Total tiles now available in table: #{conn.select_value('SELECT count(*) FROM local_map_tiles')}"
  end

  def self.seed_local_map_tiles_from_file
    ActiveRecord::Base.establish_connection :zl_gis
    ActiveRecord::Base.with_connection do |conn|
      start_time = Time.now
      puts "🚀 Starting XYZ Map Tile Seeding for Zoom 9 (VK/ZL Landmasses)..."

      regions = [ { name: "New Zealand", z: 9, x_range: (492..511), y_range: (307..334) } ]

      # Calculate total tiles to download
      total_tiles = regions.sum { |r| r[:x_range].size * r[:y_range].size }
      puts "Total tiles to process: #{total_tiles}"

      processed_count = 0
      inserted_count  = 0

      regions.each do |region|
        puts "\n🌍 Processing #{region[:name]}..."
        z = region[:z]

        region[:x_range].each do |x|
          # Array bucket to collect rows for small batch inserts
          batch_rows = []

          region[:y_range].each do |y|
            processed_count += 1

            # Print a progress indicator every 100 tiles
            if processed_count % 100 == 0 || processed_count == total_tiles
              percent = ((processed_count.to_f / total_tiles) * 100).round(1)
              print "\rProgress: #{processed_count}/#{total_tiles} tiles checked (#{percent}%)"
              $stdout.flush
            end

            puts "/home/mbriggs/9/#{x}/#{y}"

            file_data=nil
            begin
              file_data = File.read("/home/mbriggs/9/#{x}/#{y}.png", mode: "rb")
            rescue
              puts "no such tile"
            end
            if file_data.present?
              # 2. CRITICAL: Hex-encode the binary bytes so it is safe for an SQL string injection
              escaped_hex = PG::Connection.escape_bytea(file_data)
              # 2. Wrap it in single quotes so it compiles perfectly inside the VALUES string
              batch_rows << "(#{z}, #{x}, #{y}, '#{escaped_hex}', NOW(), NOW())"
              inserted_count += 1
            end
          end

          # 4. Commit this column batch to the database in a single fast bulk insert query
          if batch_rows.any?
            conn.execute(<<~SQL)
            INSERT INTO local_map_tiles (z, x, y, tile_bytes, created_at, updated_at)
            VALUES #{batch_rows.join(',')}
            ON CONFLICT (z, x, y) DO NOTHING;
          SQL
          end
      end
    end
  end

  #    duration = (Time.now - start_time).round(1)
  puts "\n\n🎉 Seeding Complete!"
  puts "⏱️ Time taken: #{duration} seconds"
  puts "💾 New tiles downloaded and saved: #{inserted_count}"
  puts "📚 Total tiles now available in table: #{conn.select_value('SELECT count(*) FROM local_map_tiles')}"
end
end
