# frozen_string_literal: true

# typed: false
class Crownpark < ActiveRecord::Base
  require 'csv'

  # To load new doc parks layer
  # add 'id column tio eaxch row
  # change POLYGON (( to MULTIPOLYGON ((( and ))" to )))"
  # # change row titrles to id, Overlays: nil, NaPALIS_ID: nil, End_Date: nil, Vested: nil, Section: nil, Classified: nil, Legislatio: nil, Recorded_A: nil, Conservati: nil, Control_Ma: nil, Government: nil, Private_Ow: nil, Local_Purp: nil, Type: nil, Start_Date: nil, Name: nil, WKT: nil

  # in psql delete old database: delete from docparks;
  # rails c production
  # Crownparks.my_import(filename.csv)
  # update crownparks set ctrl_mg_vst=NULL where ctrl_mg_vst='NULL'
  # Park.update_table

  # establish_connection "crownparks"

  def self.ecan_import(file)
    h = []
    CSV.foreach(file, headers: true) do |row|
      h.push(row.to_hash)
    end

    h.each do |park|
      p = Crownpark.new
      p.name = park['COMMON_NAM']
      p.WKT = park['WKT']
      p.reserve_type = 'Regional park'
      p.start_date = park['DATE_CREAT']
      p.recorded_area = park['Shape_Area'].to_d / 10_000

      p.save
      puts 'Added crownpark :' + p.id.to_s + ' - ' + p.name
    end
  end

  def self.my_import(file)
    # conn=Crownpark.get_custom_connection("cps",'crownparks','mbriggs','littledog')
    # cat filename | sed 's/MULTIP/SRID=4326; MULTIP/g' > filename2
    # copy crownparks("WKT",napalis_id,start_date,name,recorded_area,overlays,reserve_type,legislation,section,reserve_purpose,ctrl_mg_vst) from '/home/mbriggs/protected-areas.csv' DELIMITER ',' CSV HEADER;

    #  count=0
    #  CSV.foreach(file, :headers => true) do |row|
    #    h=row.to_hash
    #    h.shift
    #    self.create!(h)
    #    puts count
    #    count+=1
    #  end
  end

  def self.merge_nearby
    #  ActiveRecord::Base.connection.execute("update crownparks set master_id=id where master_id is null;")
    count = 0
    hundreds = 0
    #  conn=Crownpark.get_custom_connection("cps",'crownparks','mbriggs','littledog')
    ls = Crownpark.where(is_active: true).order(:id)
    puts ls.count
    ls.each do |l|
      l.reload
      count += 1
      print '#'
      $stdout.flush
      if count >= 100
        count = 0
        hundreds += 1
        puts 'Count: ' + (hundreds * 100).to_s
      end
      next unless l.is_active && l.name && !l.name.empty?
      ls = Crownpark.find_by_sql [' SELECT cp2.id from crownparks cp1
       inner join crownparks cp2
       ON cp2.is_active=true and (cp2.name = cp1.name) and cp2.id != cp1.id and ST_DWithin(cp1."WKT",cp2."WKT", 20000, false)
       where cp1.id= ' + l.id.to_s + ';']

      next unless !ls.nil? && ls.count.positive?
      ids = ls.map(&:id).join(',')
      ids = ids + ',' + l.id.to_s
      ids.split(',').each do |l2|
        areas = Crownpark.find_by_sql [' select ST_Area("WKT") as id from crownparks where id in (' + l2 + '); ']
        puts 'Areas before merge: ' + areas.first.id.to_s
      end

      ls.each do |ll|
        ActiveRecord::Base.connection.execute('update crownparks set is_active=false, master_id=' + l.id.to_s + ' where id=' + ll.id.to_s + ';')
        l2 = Crownpark.find_by_id(ll)
        #          l2.is_active=false
        #          l2.master_id=l.id;
        #          l2.save
        puts 'Merged and deleted ' + (l2.name || 'unnamed') + ' ' + l2.id.to_s + ' as duplicate of ' + (l.name || 'unnamed') + l.id.to_s
      end
      ActiveRecord::Base.connection.execute('update crownparks set "WKT"=(select st_multi(ST_CollectionExtract(st_collect("WKT"),3)) as "WKT" from crownparks where id in (' + ids + ')) where id=' + l.id.to_s + '; ')
      badids = Crownpark.find_by_sql [' select id from crownparks where id=' + l.id.to_s + ' and ST_IsValid("WKT")=false; ']
      if badids && badids.count.positive?
        puts 'Created invalid geometry'
        ActiveRecord::Base.connection.execute('update crownparks set "WKT"=st_multi(ST_CollectionExtract(ST_MakeValid("WKT"),3)) where id=' + badids.first.id.to_s + ';')
      end

      areas = Crownpark.find_by_sql [' select ST_Area("WKT") as id from crownparks where id in (' + l.id.to_s + '); ']
      puts 'Area after merge: ' + areas.first.id.to_s
    end
    true
  end

  def self.fix_invalid_polygons
    ids = Crownpark.find_by_sql [' select id from crownparks where ST_IsValid("WKT")=false; ']
    ids.each do |id|
      puts id.id
      ActiveRecord::Base.connection.execute('update crownparks set "WKT"=st_multi(ST_CollectionExtract(ST_MakeValid("WKT"),3)) where id=' + id.id.to_s + ';')
    end
  end

  def self.get_custom_connection(identifier, dbname, dbuser, password)
    eval("Custom_#{identifier} = Class::new(ActiveRecord::Base)")
    eval("Custom_#{identifier}.establish_connection(:adapter=>'postgis', :database=>'#{dbname}', " \
    ":username=>'#{dbuser}', :password=>'#{password}')")
    eval("Custom_#{identifier}.connection")
  end
end
