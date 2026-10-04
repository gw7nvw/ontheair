# frozen_string_literal: true

# typed: false
class Nzgdb < ApplicationRecord
  require 'csv'
  before_validation :truncate_long_strings
  establish_connection :nzgdb

  attr_accessor :theorder
  def self.update
    url = "https://gazetteer.linz.govt.nz/gaz.csv"
    data = fetch_external_url(url)
    fields = data.parse_csv
    fields = fields.map { |s| s.gsub(/[^0-9a-z _]/, '')}
    values = CSV(data).read

    rowcount = 0
    values.each do |s|
      rowcount+=1
      next if rowcount==1
      name_id = s[fields.index("name_id")]
      name = s[fields.index("name")]
      attributes = fields.zip(s).to_h
      safe_attributes = attributes.slice(*Nzgdb.attribute_names)
      n=Nzgdb.find_by(name_id: name_id.to_i)
      if !n then
        result=Nzgdb.create(safe_attributes)
        if !result
          puts "FAILED TO CREATE: #{safe_attributes.to_json}"
        else
          puts "NEW RECORD: #{name}"
        end
      else
        n.update(safe_attributes)
        if n.saved_changes?
          puts "UPDATED RECORD: #{name} - #{n.saved_changes.keys.to_json}"
        end
      end
      if n.saved_changes.keys.include?('status')
        n.update_column(:is_active, true) 
        puts "Status changed - Reactivating #{name}"
      end
      if (n.status=='Unofficial Replaced' or n.status=='Unofficial Discontinued') and n.is_active==true
        n.update_column(:is_active, false) 
        puts "Retiring #{name}"
      end
    end

    Nzgdb.remove_duplicates()
  end

  def self.import(filename)
    CSV.foreach(filename, headers: true) do |row|
      place = row.to_hash
      unless ['Unofficial Replaced', 'Unofficial Discontinued'].include?(row['status'])
        newplace = {}
        place.each do |key, value|
          key = key.gsub(/[^0-9a-z _]/i, '')
          newplace[key] = value
        end
        p = Nzgdb.new(newplace)
        p.save
        puts p.id
      end
    end
  end

  def self.remove_duplicates
    status = {}
    status['Official Approved'] = 1
    status['Official Official By Other Legislation'] = 2
    status['Official Validated'] = 3
    status['Official Valid'] = 4
    status['Official Adopted'] = 5
    status['Official Assigned'] = 6
    status['Official Altered'] = 7
    status['Unofficial Recorded'] = 8
    status['Unofficial Collected'] = 9
    status['Unofficial Original Moriori Name'] = 10
    status['Unofficial Original Māori Name'] = 10

    ls = Nzgdb.where(is_active: true)
    ls.each do |l|
      l.reload
      next unless l.is_active
      dups = Nzgdb.where('feat_id = ? and is_active=true', l.feat_id)
      next unless dups && (dups.count > 1)
      puts l.feat_id
      minstatus = 100
      dups.each do |dup|
        dup.theorder = status[dup.status]
        minstatus = dup.theorder if dup.theorder < minstatus
      end
      count = 0
      name = ''
      id = nil
      dups.each do |dup|
        if dup.theorder == minstatus
          dup.is_active = true
          count += 1
          if count > 1
            puts 'MERGE:   ' + dup.status + ' - ' + dup.name
            dup.is_active = false
            name += ' / ' + dup.name
          else
            puts 'KEEP:   ' + dup.status + ' - ' + dup.name
            name = dup.name
            id = dup.id
          end
        else
          dup.is_active = false
          puts 'DELETE: ' + dup.status + ' - ' + dup.name
        end
        dup.save
      end
      if count > 1
        puts 'MERGED: ' + name
        p = Nzgdb.find(id)
        p.name = name
        p.save
      end
      puts '================'
    end; true
  end

  def self.first_by_id
    Nzgdb.where('id > ?', 0).order(:id).first
  end

  def self.next(id)
    Nzgdb.where('id > ?', id).order(:id).first
  end
    private

  def truncate_long_strings
    # 1. Iterate over every attribute currently assigned to this record
    attributes.each do |column_name, value|
      next unless value.is_a?(String) && !value.nil?

      # 2. Grab the schema properties for this column from the database adapter
      column_spec = self.class.columns_hash[column_name]
      next unless column_spec

      # 3. Pull out the maximum character limit (e.g. 255 for standard string columns)
      limit = column_spec.limit

      # 4. Truncate if a limit exists and the current value is too long
      if limit && value.length > limit
        # Use [0...limit] to cleanly slice the exact maximum allowed characters
        self[column_name] = value[0...limit]
      end
    end
  end
end
