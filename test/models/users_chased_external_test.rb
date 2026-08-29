# typed: strict
require "test_helper"

class UserChasedExternalTest < ActiveSupport::TestCase
  test "External chase listed" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1)
    chase=create_test_external_chase(activation,user2,asset1)

    assert user2.chased(include_external: true)==[asset1.code], "Chasing user has chased location 1"
    assert user2.chased==[], "External chase not included if not requested"
    assert user2.chased(include_external: false)==[], "External chase not included if not requested"
    assert user1.chased(include_external: true)==[], "Activating user has not chased location 1"
  end

  test "Duplicate external chase listed once" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    chase=create_test_external_chase(activation,user2,asset1,time: '2022-01-01'.to_time)
    activation2=create_test_external_activation(user1,asset1,date: '2022-01-02'.to_date)
    chase2=create_test_external_chase(activation2,user2,asset1,time: '2022-01-01'.to_time)

    assert user2.chased(include_external: true)==[asset1.code], "Chasing user has chased location 1 only once"
  end

  test "External chase duplicate of internal listed once" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-02'.to_date)
    chase=create_test_external_chase(activation,user2,asset1,time: '2022-01-02'.to_time)
    log=create_test_log(user1,asset_codes: [asset1.code], date: '2022-01-02'.to_date)
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], date: '2022-01-02'.to_date, time: '2022-01-02'.to_time)

    assert user2.chased(include_external: true)==[asset1.code], "Chasing user has chased location 1 only once"
  end

  
  test "External chases listed by day" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    chase=create_test_external_chase(activation,user2,asset1,time: '2022-01-01'.to_time)
    activation2=create_test_external_activation(user1,asset1,date: '2022-01-02'.to_date)
    chase2=create_test_external_chase(activation2,user2,asset1,time: '2022-01-02'.to_time)

    assert user2.chased(include_external: true, by_day: true)==[asset1.code+" 2022-01-01", asset1.code+" 2022-01-02"], "Chasing user has chased location twice"
  end

  test "External chase duplicate of internal listed once by day" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    chase=create_test_external_chase(activation,user2,asset1,time: '2022-01-01'.to_time)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], date: '2022-01-01'.to_date, time: '2022-01-01'.to_time)

    assert user2.chased(include_external: true, by_day: true)==[asset1.code+" 2022-01-01"], "Chasing user has chased location 1 only once"
  end

  test "External chase not duplicate of internal both listed by day" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    chase=create_test_external_chase(activation,user2,asset1,time: '2022-01-01'.to_time)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], date: '2022-01-02'.to_date, time: '2022-01-02'.to_time)

    assert user2.chased(include_external: true, by_day: true).sort==[asset1.code+" 2022-01-01", asset1.code+" 2022-01-02"].sort, "Chasing user has chased location 1 twice"
  end
  
  test "External activations listed by year" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    chase=create_test_external_chase(activation,user2,asset1,time: '2022-01-01'.to_time)
    activation2=create_test_external_activation(user1,asset1,date: '2022-01-02'.to_date)
    chase2=create_test_external_chase(activation2,user2,asset1,time: '2022-01-02'.to_time)
    activation3=create_test_external_activation(user1,asset1,date: '2023-01-02'.to_date)
    chase3=create_test_external_chase(activation3,user2,asset1,time: '2023-01-02'.to_time)

    assert user2.chased(include_external: true, by_year: true).sort==[asset1.code+" 2022", asset1.code+" 2023"].sort, "Activating user has activated location twice"
  end

  test "External chase duplicate of internal listed once by year" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    chase=create_test_external_chase(activation,user2,asset1,time: '2022-01-01'.to_time)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], date: '2022-01-02'.to_date, time: '2022-01-02'.to_time)

    assert user2.chased(include_external: true, by_year: true)==[asset1.code+" 2022"], "Chasing user has chased location 1 only once"
  end

  test "External chase not duplicate of internal both listed by year" do
    user1=create_test_user
    user2=create_test_user
    asset1=create_test_asset
    activation=create_test_external_activation(user1,asset1,date: '2022-01-01'.to_date)
    chase=create_test_external_chase(activation,user2,asset1,time: '2022-01-01'.to_time)
    log=create_test_log(user1,asset_codes: [asset1.code])
    contact=create_test_contact(user1,user2,log_id: log.id, asset1_codes: [asset1.code], date: '2023-01-01'.to_date, time: '2023-01-01'.to_time)

    assert user2.chased(include_external: true, by_year: true).sort==[asset1.code+" 2022", asset1.code+" 2023"].sort, "Chasing user has chased location 1 twice"
  end
end

