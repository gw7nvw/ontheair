require 'test_helper'
require 'minitest/mock'

class ConsolidatedSpotNotificationsTest < ActiveSupport::TestCase
  setup do
    SentNotification.delete_all
    ConsolidatedSpot.delete_all
    UserNotificationLink.delete_all

    # Set up matching data structure
    @user=create_test_user(push_app_token: "app123", push_user_token: "usr123", push_include_external: true)

    
  end

  test "send notification once, do not resend if local update occurs" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: ["EU"], bands: [], modes: ["CW"], spot_types: [], activator_callsign: "", code: "", priority: 0)
    # 1. Stub the MapImageService to return a fake dummy binary string instead of doing real tile work
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      
      #Step 1 - submit notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "CW",
          code: ["G/SP-001"],
        )
      end

      #Step 2: Trigger renotify on this spot and verify no additional notification sent

      # We expect send_alert to receive ZERO calls because the ledger should throttle it
      mock_pushover = Minitest::Mock.new # No expectations defined means any call will blow it up

      PushoverService.stub :send_alert, ->(payload) { mock_pushover.call(payload) } do
          
        assert_no_difference -> { SentNotification.count } do
          SendNotifications.perform(ConsolidatedSpot.last.id, false) # is_new_record: false
        end
      end
    end
  end

  test "trigger notifiction on continents" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: ["EU"], bands: [], modes: ["CW"], spot_types: [], activator_callsign: "", code: "", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit matching notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "CW",
          code: ["G/SP-001"],
        )
      end

      #Step 2 - submit non-matching notification and verify that notifiction is not sent
      assert_difference -> { SentNotification.count }, 0 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "CW",
          code: ["VK1/SP-001"],
        )
      end

      #Step 3 - submit blank notification and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "CW",
          code: [],
        )
      end
    end
  end

  test "trigger notifiction when no continents listed" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: [], bands: [], modes: ["CW"], spot_types: [], activator_callsign: "", code: "", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit matching notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "CW",
          code: ["G/SP-001"],
        )
      end
    end
  end

  test "trigger notifiction on bands" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: [], bands: ["20m"], modes: ["CW"], spot_types: [], activator_callsign: "", code: "", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit matching notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "CW",
          code: ["G/SP-001"],
        )
      end

      #Step 2 - submit non-matching notification and verify that notifiction is not sent
      assert_difference -> { SentNotification.count }, 0 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "7.040",
          mode: "CW",
          code: ["G/SP-001"],
        )
      end

      #Step 3 - submit blank notification and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "",
          mode: "CW",
          code: [],
        )
      end
    end
  end

  test "trigger notifiction when no bands listed" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: [], bands: [], modes: ["CW"], spot_types: [], activator_callsign: "", code: "", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit matching notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "CW",
          code: ["G/SP-001"],
        )
      end
    end
  end

  test "trigger notification on modes" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: [], bands: [], modes: ["SSB","AM"], spot_types: [], activator_callsign: "", code: "", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit matching notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["G/SP-001"],
        )
      end

      #Step 2 - submit non-matching notification and verify that notifiction is not sent
      assert_difference -> { SentNotification.count }, 0 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "7.040",
          mode: "CW",
          code: ["G/SP-001"],
        )
      end

      #Step 3 - submit blank notification and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "",
          mode: "",
          code: ["G/SP-001"],
        )
      end

      #Step 4 - submit 2nd mode notification and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "",
          mode: "AM",
          code: ["G/SP-001"],
        )
      end
    end
  end

  test "trigger notifiction when no modes listed" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: ["EU"], bands: [], modes: [], spot_types: [], activator_callsign: "", code: "", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit matching notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "CW",
          code: ["G/SP-001"],
        )
      end
    end
  end

  test "trigger notification on spot_types" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: [], bands: [], modes: [], spot_types: ["WWFF", "POTA"], activator_callsign: "", code: "", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit matching notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["GFF-0001"],
          spot_type: ["WWFF"],
          name: [""]
        )
      end

      #Step 2 - submit non-matching notification and verify that notifiction is not sent
      assert_difference -> { SentNotification.count }, 0 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "7.040",
          mode: "SSBCW",
          code: ["G/SP-001"],
          spot_type: ["SOTA"], 
          name: [""]
        )
      end

      #Step 3 - submit blank notification and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "",
          mode: "SSB",
          code: [],
          spot_type: ["WWFF"], 
          name: [""]
        )
      end

      #Step 4 - submit 2nd mode notification and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "",
          mode: "SSB",
          code: ["G-1224"],
          spot_type: ["POTA"], 
          name: [""]
        )
      end

      #step 5 - multiple spot types in spot
        assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "",
          mode: "SSB",
          code: ["G/SP-001", "G-1224"],
          spot_type: ["SOTA", "POTA"],
          name: ["", ""]
        )
      end

      #step 6 - nd the reverse order
        assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "",
          mode: "SSB",
          code: ["G-1224", "G/SP-001"],
          spot_type: ["POTA", "SOTA"],
          name: ["", ""]
        )
      end
    end
  end

  test "trigger notification on callsign" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: [], bands: [], modes: [], spot_types: ["WWFF"], activator_callsign: "G*,F*", code: "", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit matching notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["GFF-0001"],
          spot_type: ["WWFF"],
          name: [""] 
        )
      end
      #Step 2 - submit non-matching notification and verify that notifiction is not sent  
      assert_difference -> { SentNotification.count }, 0 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "DL4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["GFF-0001"],
          spot_type: ["WWFF"],
          name: [""] 
        )
      end
      #Step 3 - submit second-choice callsign notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "F4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["GFF-0001"],
          spot_type: ["WWFF"],
          name: [""] 
        )
      end
    end
  end

  test "trigger notification on code" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: [], bands: [], modes: [], spot_types: ["WWFF"], activator_callsign: "", code: "G*,F*", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit matching notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["GFF-0001"],
          spot_type: ["WWFF"],
          name: [""] 
        )
      end
      #Step 2 - submit non-matching notification and verify that notifiction is not sent  
      assert_difference -> { SentNotification.count }, 0 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "DL4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["DLFF-0001"],
          spot_type: ["WWFF"],
          name: [""] 
        )
      end
      #Step 3 - submit second-choice code notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "F4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["FFF-0001"],
          spot_type: ["WWFF"],
          name: [""] 
        )
      end
      #Step 4 - multiple codes notification and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "F4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["DLFF-0001", "FFF-0001"],
          spot_type: ["WWFF", "WWFF"],
          name: ["", ""] 
        )
      end
      #Step 5 - and the reverse order and verify that notifiction is sent  
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "F4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["FFF-0001", "DLFF-0001"],
          spot_type: ["WWFF", "WWFF"],
          name: ["", ""] 
        )
      end
    end
  end

  test "trigger notification on update if type changes" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: [], bands: [], modes: [], spot_types: ["POTA"], activator_callsign: "", code: "", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit non-matching notification and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 0 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["DLFF-0001"],
          spot_type: ["WWFF"],
          name: [""]
        )
      end
      #Step 2 - submit non-matching notification and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 1 do
        @spot.code = ["FFF-0001", "F-0001"]
        @spot.spot_type = ["WWFF", "POTA"]
        @spot.name = ["", ""]
        @spot.save
      end
    end
  end

  test "do not trigger notification on update if type does not changes" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: [], bands: [], modes: [], spot_types: ["WWFF"], activator_callsign: "", code: "", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit non-matching notification and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 1 do
        @spot = ConsolidatedSpot.create(
          activatorCallsign: "G4ABC",
          frequency: "14.040",
          mode: "SSB",
          code: ["DLFF-0001"],
          spot_type: ["WWFF"],
          name: [""]
        )
      end
      #Step 2 - submit non-matching notification and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 0 do
        @spot.comments=["Hi", "Bye"]
        @spot.callsign=["F1A","F1B"]
        @spot.time = [Time.now.to_s, Time.now.to_s]
        @spot.save
      end
    end
  end

  test "trigger notification from local spot" do
    link = UserNotificationLink.create(user_id: @user.id,  continents: [], bands: [], modes: [], spot_types: ["POTA"], activator_callsign: "", code: "", priority: 0)
    MapImageService.stub :generate_matrix, "fake_binary_jpeg_blob" do
      #Step 1 - submit matching spot post and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 1 do
        item=create_test_spot(@user, asset_codes: ["NZ-0001"], description: "cq cq", mode: "SSB", freq: "7.085", callsign: "ZL0ABC")
        spot=item.post
      end
      #Step 2 - submit non-matching notification and verify that notifiction is sent
      assert_difference -> { SentNotification.count }, 0 do
        item=create_test_spot(@user, asset_codes: ["ZLFF-0001"], description: "cq cq", mode: "SSB", freq: "7.085", callsign: "ZL0ABC")
        spot=item.post
      end
    end
  end


end
