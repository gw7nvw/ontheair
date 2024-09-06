require "test_helper"

class AssetLinksTest < ActiveSupport::TestCase

  test "photos listed" do
     #TODO
  end

  test "Contacts listed" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact1=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code])
    log2=create_test_log(user1)
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset2_codes: [asset1.code])
    contact4=create_test_contact(user1,user2,log_id: log2.id, asset2_codes: [asset2.code])

    assert asset1.contacts.sort==[contact1, contact2, contact3],
       "All contacts as activator or chaser log listed"
  end

  test "Logs listed" do
    user1=create_test_user
    user2=create_test_user
    user3=create_test_user
    asset1=create_test_asset
    asset2=create_test_asset
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact1=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code])
    contact2=create_test_contact(user1,user3,log_id: log.id, asset1_codes: [asset1.code])
    log2=create_test_log(user1)
    contact3=create_test_contact(user1,user2,log_id: log2.id, asset2_codes: [asset1.code])
    contact4=create_test_contact(user1,user2,log_id: log2.id, asset2_codes: [asset2.code])

    assert asset1.logs.sort==[log]
       "All logs for activators listed"
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
    a=asset4.traditional_owners; assert a==nil, "No owners returned where no data: "+a.to_s
  end
end
