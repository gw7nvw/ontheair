# frozen_string_literal: true

# typed: false
class AssetWebLink < ActiveRecord::Base
  require 'csv'

  def web_link_class
    WebLinkClass.find_by(name: link_class)
  end

  def self.import_climbnz(file, outfile)
    h = []
    CSV.foreach(file, headers: true) do |row|
      h.push(row.to_hash)
    end
    filetext = "'url','name','alt'\n"

    h.each do |peak|
      puts peak
      puts peak['name']
      next unless peak && peak['name']
      shortname = peak['name']
      longname = shortname.gsub('Pk', 'Peak').gsub('Mt', 'Mount')
      asset = nil
      a = Asset.where("(name = '#{shortname}' or name = '#{longname}') and altitude=#{peak['alt']} and asset_type='summit'")
      if a.count == 1
        puts 'Matched: ' + a.first.code + "] '" + a.first.name + "' with '#{shortname}'"
        asset = a.first
      end
      if a.count > 1
        puts "Multiple matches: '#{shortname}' - #{peak['alt']} - #{peak['url']}"
        count = 0
        a.each do |_ass|
          puts count.to_s + ': [' + a[count].code + "] '" + a[count].name
          count += 1
        end
        puts 'Select match (or ENTER to ignore):'
        id = gets
        asset = a[id.to_i] if id && !id.empty? && (id.to_i < a.count)
      end
      if !a || a.count.zero?
        puts "No match for: '#{shortname}' - #{peak['alt']} - #{peak['url']}"
      end
      if asset
        AssetWebLink.create(asset_code: asset.code, url: 'https://climbnz.org.nz' + peak['url'], link_class: 'climbnz')
      else
        filetext += "'#{peak['url']}','#{peak['name']}',#{peak['alt']}\n"
      end
    end
    File.open(outfile, 'w') { |thefile| thefile.write(filetext) }
  end
end
