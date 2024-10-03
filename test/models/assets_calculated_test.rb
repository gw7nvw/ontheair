# typed: strict
require "test_helper"

class AssetCalculatedTest < ActiveSupport::TestCase

  test "Maidenhead for asset" do
    asset1=create_test_asset(location: create_point(174,-40))
    assert asset1.maidenhead=='RF70aa', "Correct maidenhead: "+asset1.maidenhead
  end

  test "NZTM for asset" do
    asset1=create_test_asset(location: create_point(174,-40))
    assert asset1.x.to_i==1685360, "Correct NZTM X: "+asset1.x.to_s
    assert asset1.y.to_i==5571763, "Correct NZTM Y: "+asset1.y.to_s
  end

  test "names" do
    asset1=create_test_asset(location: create_point(172,-40.5))
    assert asset1.district_name=='Christchurch', "Correct district: "+asset1.district_name
    assert asset1.region_name=='Canterbury', "Correct region: "+asset1.region_name
  end

  test "Web links listed" do
    user1=create_test_user
    asset1=create_test_asset
    create_test_web_link(asset1, "https://google.com", "other")
    create_test_web_link(asset1, "https://hutbagger.co.nz/image.jpg", "hutbagger")
   
    awls=asset1.web_links.sort
    assert awls[0][:url]=="https://google.com"
    assert awls[1][:url]=="https://hutbagger.co.nz/image.jpg"
    assert awls.count==2

    hbl=asset1.hutbagger_link
    assert hbl[:url]=="https://hutbagger.co.nz/image.jpg"
  end

  test "Asset type" do
    asset1=create_test_asset(asset_type: 'hut')
    assert asset1.type==AssetType.find_by(name: 'hut'), "Correct asset type returned"

    asset2=Asset.new
    assert asset2.type==AssetType.find_by(name: 'all'), "Return 'all' for unknown type"

  end

  test "Tribal land returns iwi where known" do
    #should probably use test iwi
    #location within 1 iwi
    asset1=create_test_asset(asset_type: 'hut', location: create_point(172,-42))
    a=asset1.traditional_owners; assert a=='Ngāi Tahu country', "Correct owners returned: "+a.to_s
    #location within 2 iwi
    asset2=create_test_asset(asset_type: 'park', location: create_point(172,-40), test_radius: 0.01)
    a=asset2.traditional_owners; assert a=='In or near Ngāti Apa, Ngāi Tahu country', "Correct multiple owners returned: "+a.to_s
    #location near boundary
    asset3=create_test_asset(asset_type: 'hut', location: create_point(172,-40.0001))
    a=asset3.traditional_owners; assert a=='In or near Ngāti Apa, Ngāi Tahu country', "Correct vague answer rturned ner boundary: "+a.to_s
    #location  with no data
    asset4=create_test_asset(asset_type: 'hut', location: create_point(167,-40.0001))
    a=asset4.traditional_owners; assert_nil a, "No owners returned where no data: "+a.to_s
  end

  test "First activated from activator log" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 01:00'.to_time)
    log2=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-01'.to_date)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: '2022-01-01 01:00'.to_time)
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset1_codes: [asset1.code], time: '2022-01-01 00:59'.to_time)
    
    assert asset1.first_activated==contact3, "Earliest contact returned for first activated: "+asset1.first_activated.to_json
  end
  test "First activated from chaser log" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset(asset_type: 'hut')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 01:00'.to_time)
    log2=create_test_log(user1, date: '2022-01-01'.to_date)
    contact2=create_test_contact(user1,user2,log_id: log2.id, asset2_codes: [asset1.code], time: '2022-01-01 01:00'.to_time)
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset2_codes: [asset1.code], time: '2022-01-01 00:59'.to_time)
    
    assert asset1.first_activated==contact3.reverse, "Earliest contact returned for first activated: "+asset1.first_activated.to_json
  end
  test "First activated from external activator log" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/CB=')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 01:00'.to_time)
    activation2=create_test_external_activation(user3,asset1,date: '2022-01-01'.to_date)
 
    assert asset1.first_activated.callsign1==user3.callsign, "Earliest contact returned for first activated when in external activation: "+asset1.first_activated.to_json
  end
  test "First activated from external chaser log" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/CB=')
    log=create_test_log(user1, asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], time: '2022-01-02 01:00'.to_time)
    activation2=create_test_external_activation(user3,asset1,date: '2022-01-01'.to_date)
    chase2=create_test_external_chase(activation2,user2,asset1,time: '2022-01-01 02:00'.to_time)
 
    assert asset1.first_activated.callsign1==user3.callsign, "Earliest contact returned for first activated when in external activation: "+asset1.first_activated.to_json
    assert asset1.first_activated.callsign1==user3.callsign, "Earliest contact returned for first activated when in external chase (callsign1): "+asset1.first_activated.to_json
    assert asset1.first_activated.callsign2==user2.callsign, "Earliest contact returned for first activated when in external chase (callsign2): "+asset1.first_activated.to_json
  end

  test "Correct external URL for internal assets: POTA" do
    asset1=create_test_asset(asset_type: 'pota park', code_prefix: 'NZ-0')
    assert_equal 'https://pota.app/#/park/'+asset1.code, asset1.external_url, "POTA URL correct"
  end

  test "Correct external URL for internal assets: WWFF" do
    asset1=create_test_asset(asset_type: 'wwff park', code_prefix: 'ZLFF-0')
    assert_equal 'https://wwff.co/directory/?showRef='+asset1.code, asset1.external_url, "WWFF URL correct"
  end

  test "Correct external URL for internal assets: SOTA" do
    asset1=create_test_asset(asset_type: 'summit', code_prefix: 'ZL3/OT-')
    assert_equal 'https://www.sotadata.org.uk/en/summit/'+asset1.code, asset1.external_url, "SOTA URL correct"
  end

  test "Correct external URL for internal assets: HEMA" do
    asset1=create_test_asset(asset_type: 'hump', code_prefix: 'ZL3/HOT-',old_code: 612345)
    assert_equal 'http://www.hema.org.uk/fullSummit.jsp?summitKey='+asset1.old_code, asset1.external_url, "HEMA URL correct"
  end
end
