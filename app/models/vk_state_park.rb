# frozen_string_literal: true
# typed: strict

class VkStatePark < ActiveRecord::Base
  require 'csv'
  self.primary_key = "id"
  establish_connection :capad
  self.table_name = "vk_state_park"

  def self.import_vic(filename)
     conn = Asset.get_custom_connection('cp', 'capad', 'mbriggs', 'littledog')

     count = 0
     CSV.foreach(filename, headers: true) do |row|
      count += 1
      place = row.to_hash
      np = VkStatePark.new
      np.name = place['name']
      np.boundary = place['WKT']
      np.owner = place['rec_cat']
      np.state = 'VIC'
      np.unique_name = np.state + "_" + (if np.name then np.name else place['plm_id'] end)
      dp = nil
      dp = VkStatePark.find_by(name: np.name) if np.name and np.name.length>0
      np.save
      np.reload
      if dp then
        puts np
        result = conn.execute("update vk_state_park set boundary = (select ST_Multi(ST_Union (boundary)) as boundary from vk_state_park where id in (#{dp.id.to_s}, #{np.id.to_s})) where id = #{dp.id.to_s};")
         puts result.to_s
        puts "Adding polygon to #{dp.name}"
        np.destroy
      else
        puts "Creating: "+(np.name||"")+" (#{count.to_s})"
      end
    end
  end

  def self.import_nsw(filename)
     conn = Asset.get_custom_connection('cp', 'capad', 'mbriggs', 'littledog')

     count = 0
     CSV.foreach(filename, headers: true) do |row|
      count += 1
      place = row.to_hash
      np = VkStatePark.new
      np.name = place['SFName']+" State Forest"
      np.boundary = place['WKT']
      np.owner = 'State Forest'
      np.state = 'NSW'
      np.unique_name = np.state + "_" + (if np.name then np.name else place['SFNo'] end)
      dp = nil
      dp = VkStatePark.find_by(name: np.name) if np.name and np.name.length>0
      np.save
      np.reload
      if dp then
        puts np
        result = conn.execute("update vk_state_park set boundary = (select ST_Multi(ST_Union (boundary)) as boundary from vk_state_park where id in (#{dp.id.to_s}, #{np.id.to_s})) where id = #{dp.id.to_s};")
         puts result.to_s
        puts "Adding polygon to #{dp.name}"
        np.destroy
      else
        puts "Creating: "+(np.name||"")+" (#{count.to_s})"
      end
    end
  end

  def self.import_qld(filename)
     conn = Asset.get_custom_connection('cp', 'capad', 'mbriggs', 'littledog')

     count = 0
     CSV.foreach(filename, headers: true) do |row|
      count += 1
      place = row.to_hash
      np = VkStatePark.new
      np.name = place['estatename']
      np.boundary = place['WKT']
      np.owner = place['dcdbtenure']
      np.state = 'QLD'
      np.unique_name = np.state + "_" + (if np.name then np.name else place['sysintcode'] end)
      dp = nil
      dp = VkStatePark.find_by(name: np.name) if np.name and np.name.length>0
      np.save
      np.reload
      if dp then
        puts np
        result = conn.execute("update vk_state_park set boundary = (select ST_Multi(ST_Union (boundary)) as boundary from vk_state_park where id in (#{dp.id.to_s}, #{np.id.to_s})) where id = #{dp.id.to_s};")
         puts result.to_s
        puts "Adding polygon to #{dp.name}"
        np.destroy
      else
        puts "Creating: "+(np.name||"")+" (#{count.to_s})"
      end
    end
  end

  def self.import_sa(filename)
     conn = Asset.get_custom_connection('cp', 'capad', 'mbriggs', 'littledog')

     count = 0
     CSV.foreach(filename, headers: true) do |row|
      count += 1
      place = row.to_hash
      np = VkStatePark.new
      np.name = place['RESNAME']+" "+place['RESTYPE']
      np.boundary = place['WKT']
      np.owner = place['RESTYPE']
      np.state = 'SA'
      np.unique_name = np.state + "_" + (if np.name then np.name else place['PARK_ID'] end)
      dp = nil
      dp = VkStatePark.find_by(name: np.name) if np.name and np.name.length>0
      np.save
      np.reload
      if dp then
        puts np
        result = conn.execute("update vk_state_park set boundary = (select ST_Multi(ST_Union (boundary)) as boundary from vk_state_park where id in (#{dp.id.to_s}, #{np.id.to_s})) where id = #{dp.id.to_s};")
         puts result.to_s
        puts "Adding polygon to #{dp.name}"
        np.destroy
      else
        puts "Creating: "+(np.name||"")+" (#{count.to_s})"
      end
    end
  end

  def self.import_wa(filename)
     conn = Asset.get_custom_connection('cp', 'capad', 'mbriggs', 'littledog')

     count = 0
     CSV.foreach(filename, headers: true) do |row|
      count += 1
      place = row.to_hash
      np = VkStatePark.new
      np.name = place['leg_name']
      np.boundary = place['WKT']
      np.owner = place['leg_purpos']
      np.state = 'WA'
      np.unique_name = np.state + "_" + (if np.name then np.name else place['leg_identi'] end)
      dp = nil
      dp = VkStatePark.find_by(name: np.name) if np.name and np.name.length>0
      np.save
      np.reload
      if dp then
        puts np
        result = conn.execute("update vk_state_park set boundary = (select ST_Multi(ST_Union (boundary)) as boundary from vk_state_park where id in (#{dp.id.to_s}, #{np.id.to_s})) where id = #{dp.id.to_s};")
         puts result.to_s
        puts "Adding polygon to #{dp.name}"
        np.destroy
      else
        puts "Creating: "+(np.name||"")+" (#{count.to_s})"
      end
    end
  end

  def self.import_nt(filename)
     conn = Asset.get_custom_connection('cp', 'capad', 'mbriggs', 'littledog')

     count = 0
     CSV.foreach(filename, headers: true) do |row|
      count += 1
      place = row.to_hash
      np = VkStatePark.new
      np.name = place['NAME']
      np.boundary = place['WKT']
      np.owner = place['TYPE']
      np.state = 'NT'
      np.unique_name = np.state + "_" + np.name
      dp = nil
      dp = VkStatePark.find_by(name: np.name) if np.name and np.name.length>0
      np.save
      np.reload
      if dp then
        puts np
        result = conn.execute("update vk_state_park set boundary = (select ST_Multi(ST_Union (boundary)) as boundary from vk_state_park where id in (#{dp.id.to_s}, #{np.id.to_s})) where id = #{dp.id.to_s};")
         puts result.to_s
        puts "Adding polygon to #{dp.name}"
        np.destroy
      else
        puts "Creating: "+(np.name||"")+" (#{count.to_s})"
      end
    end
  end
  def self.import_tas(filename)
     conn = Asset.get_custom_connection('cp', 'capad', 'mbriggs', 'littledog')

     count = 0
     CSV.foreach(filename, headers: true) do |row|
      count += 1
      place = row.to_hash
      np = VkStatePark.new
      np.name = place['NAME']
      np.boundary = place['WKT']
      np.owner = place['CATEGORY']
      np.state = 'TAS'
      np.unique_name = np.state + "_" + (if np.name then np.name else place['CID'] end)
      dp = nil
      dp = VkStatePark.find_by(name: np.name) if np.name and np.name.length>0
      np.save
      np.reload
      if dp then
        puts np
        result = conn.execute("update vk_state_park set boundary = (select ST_Multi(ST_Union (boundary)) as boundary from vk_state_park where id in (#{dp.id.to_s}, #{np.id.to_s})) where id = #{dp.id.to_s};")
         puts result.to_s
        puts "Adding polygon to #{dp.name}"
        np.destroy
      else
        puts "Creating: "+(np.name||"")+" (#{count.to_s})"
      end
    end
  end
end




