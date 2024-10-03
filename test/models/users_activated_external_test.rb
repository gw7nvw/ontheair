# typed: strict
require "test_helper"

class UserActivatedExternalTest < ActiveSupport::TestCase

  test "External activation listed" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1)

    assert user1.activations(include_external: true)==[asset1.code], "Activating user has activated location 1"
    assert user1.activations==[], "External activation not included if not requested"
    assert user1.activations(include_external: false)==[], "External activation not included if not requested"
    assert user2.activations(include_external: true)==[], "Chasing user has not activated location 1"

  end

  test "Duplicate external activation listed once" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    activation2=create_test_external_activation(user1,asset1,date: '2022-01-02'.to_date)

    assert user1.activations(include_external: true)==[asset1.code], "Activating user has activated location 1 only once"
  end

  test "External activation duplicate of internal listed once" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], date: '2022-01-02'.to_date, time: '2022-01-02'.to_time)

    assert user1.activations(include_external: true)==[asset1.code], "Activating user has activated location 1 only once"
  end

  
  test "External activations listed by day" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    activation2=create_test_external_activation(user1,asset1,date: '2022-01-02'.to_date)

    assert user1.activations(include_external: true, by_day: true)==[asset1.code+" 2022-01-01", asset1.code+" 2022-01-02"], "Activating user has activated location twice"
  end

  test "External activation duplicate of internal listed once by day" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], date: '2022-01-01'.to_date, time: '2022-01-01'.to_time)

    assert user1.activations(include_external: true, by_day: true)==[asset1.code+" 2022-01-01"], "Activating user has activated location 1 only once"
  end

  test "External activation not duplicate of internal both listed by day" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], date: '2022-01-02'.to_date, time: '2022-01-02'.to_time)

    assert user1.activations(include_external: true, by_day: true).sort==[asset1.code+" 2022-01-01", asset1.code+" 2022-01-02"].sort, "Activating user has activated location 1 twice"
  end
  
  test "External activations listed by year" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    activation2=create_test_external_activation(user1,asset1,date: '2022-01-02'.to_date)
    activation3=create_test_external_activation(user1,asset1,date: '2023-01-02'.to_date)

    assert user1.activations(include_external: true, by_year: true).sort==[asset1.code+" 2022", asset1.code+" 2023"].sort, "Activating user has activated location twice"
  end

  test "External activation duplicate of internal listed once by year" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], date: '2022-01-02'.to_date, time: '2022-01-02'.to_time)

    assert user1.activations(include_external: true, by_year: true)==[asset1.code+" 2022"], "Activating user has activated location 1 only once"
  end

  test "External activation not duplicate of internal both listed by year" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], date: '2023-01-01'.to_date, time: '2023-01-01'.to_time)

    assert user1.activations(include_external: true, by_year: true).sort==[asset1.code+" 2022", asset1.code+" 2023"].sort, "Activating user has activated location 1 twice"
  end
end

