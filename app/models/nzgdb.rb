# frozen_string_literal: true

# typed: false
class Nzgdb < ActiveRecord::Base
  require 'csv'

  establish_connection 'nzgdb'

  attr_accessor :theorder
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
end
