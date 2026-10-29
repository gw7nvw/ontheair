require 'test_helper'

class ExternalSpotUpsertTest < ActiveSupport::TestCase

  setup do
    ExternalSpot.delete_all
    ConsolidatedSpot.delete_all

    # Raw API payload examples (mimicking exactly what hits your normalizers)
    @raw_sota_data = [{"id" => 416542,"timeStamp" => "2026-10-27T01:53:19.615873Z","activatorCallsign" => "JO2BWZ/2","activatorName" => "MASANORI","callsign" => "JO2BWZ","comments" => "TNX","frequency" => nil,"mode" => "","summitCode" => "JA/GF-198","summitName" => "Ganmatayama","AltM" => 430,"AltFt" => 1411,"points" => 1,"userID" => 42243,"type" => "QRT","latitude" => 35.50550079345703,"longitude" => 136.63609313964844,"epoch" => "de78576e-fdb6-4f0d-8e5d-0e5d7285d6bd"}]
    @updated_sota_data = [{"id" => 416542,"timeStamp" => "2026-10-27T01:55:19.615873Z","activatorCallsign" => "JO2BWZ/2","activatorName" => "MASANORI","callsign" => "JO2BWZ","comments" => "Corrected Location","frequency" => nil,"mode" => "","summitCode" => "JA/GF-199","summitName" => "SomewhereElse","AltM" => 430,"AltFt" => 1411,"points" => 1,"userID" => 42243,"type" => "QRT","latitude" => 35.50550079345703,"longitude" => 136.63609313964844,"epoch" => "de78576e-fdb6-4f0d-8e5d-0e5d7285d6bd"}]
    @raw_hema_data = "26/10/2026 05:47;6261;ZL4NVW;ZL3/HSL-066;NoName;7.085 (SSB);(HEMA_ASSISTANT)"
  end

  test "full ingestion pipeline ingests raw streams, deduplicates, and passes updates to consolidation" do
    # 1. Stub out the raw external internet requests.
    # We intercept your fetch methods and force them to return our mock API arrays/text.
    # This leaves your real normalizers, array loops, and upsert statements completely intact.
    ExternalSpot.stub :fetch_sota, @raw_sota_data do
      ExternalSpot.stub :fetch_hema, @raw_hema_data do
        # Stub the remaining APIs to return empty arrays so they don't block the run
        ExternalSpot.stub(:fetch_pota, []) do
          ExternalSpot.stub(:fetch_wwff, []) do
            ExternalSpot.stub(:fetch_llota, []) do
              
              # 2. Execute the REAL production worker method
              assert_difference -> { ExternalSpot.count }, 2 do
                ExternalSpot.fetch
              end
            end
          end
        end
      end
    end
    # 3. VERIFY PRODUCTION DATA INTEGRITY
    sota_spot = ExternalSpot.find_by(source_api: "SOTA", source_id: "416542")
    hema_spot = ExternalSpot.find_by(source_api: "HEMA", source_id: "36aff3626286d64d6ec4e2de23c4d632232de3413d1a1d01a42332b87d575e4c")

    #store for later
    sota_updated = sota_spot.updated_at
    hema_updated = hema_spot.updated_at

    puts sota_spot.to_json

    #check values
    assert_not_nil sota_spot
    assert_equal "JO2BWZ/2", sota_spot.activatorCallsign

    assert_not_nil hema_spot
    assert_equal "ZL4NVW", hema_spot.activatorCallsign
    assert_equal "7.085", hema_spot.frequency

    # 4. REGRESSION DEDUPLICATION CHECK
    # We're not allowed to requery spot within 30 secs, so overwrite the timer
    reset_spot_fetch_timer

    # Run the exact same worker process again with the identical payloads.
    # Your code should automatically execute the upsert conflict paths.
    assert_no_difference -> { ExternalSpot.count } do
      ExternalSpot.stub :fetch_sota, @raw_sota_data do
        ExternalSpot.stub :fetch_hema, @raw_hema_data do
          # Stub fallbacks
          ExternalSpot.stub(:fetch_pota, []) do
            ExternalSpot.stub(:fetch_wwff, []) do
              ExternalSpot.stub(:fetch_llota, []) do
                ExternalSpot.fetch
              end
            end
          end
        end
      end
    end
    sota_spot = ExternalSpot.find_by(source_api: "SOTA", source_id: "416542")
    hema_spot = ExternalSpot.find_by(source_api: "HEMA", source_id: "36aff3626286d64d6ec4e2de23c4d632232de3413d1a1d01a42332b87d575e4c")
puts sota_spot.to_json

    # Check the spots were not updated
    assert_equal sota_updated, sota_spot.updated_at
    assert_equal hema_updated, hema_spot.updated_at
  end

  test "import pipeline handle updates to existing spots (does not crete new)" do
   # This leaves your real normalizers, array loops, and upsert statements completely intact.
    ExternalSpot.stub :fetch_sota, @raw_sota_data do
      ExternalSpot.stub :fetch_hema, @raw_hema_data do
        # Stub the remaining APIs to return empty arrays so they don't block the run
        ExternalSpot.stub(:fetch_pota, []) do
          ExternalSpot.stub(:fetch_wwff, []) do
            ExternalSpot.stub(:fetch_llota, []) do

              # 2. Execute the REAL production worker method
              assert_difference -> { ExternalSpot.count }, 2 do
                ExternalSpot.fetch
              end
            end
          end
        end
      end
    end
    # 3. VERIFY PRODUCTION DATA INTEGRITY
    sota_spot = ExternalSpot.find_by(source_api: "SOTA", source_id: "416542")
    hema_spot = ExternalSpot.find_by(source_api: "HEMA", source_id: "36aff3626286d64d6ec4e2de23c4d632232de3413d1a1d01a42332b87d575e4c")

    assert_not_nil sota_spot
    assert_equal "JO2BWZ/2", sota_spot.activatorCallsign
    assert_equal "JA/GF-198", sota_spot.code
    assert_equal "TNX", sota_spot.comments

    assert_not_nil hema_spot
    assert_equal "ZL4NVW", hema_spot.activatorCallsign
    assert_equal "7.085", hema_spot.frequency

    # We're not normally allowed to requery spot within 30 secs, so reset the timer
    reset_spot_fetch_timer

    # Apply same spots with uopdated data
    assert_no_difference -> { ExternalSpot.count } do
      ExternalSpot.stub :fetch_sota, @updated_sota_data do
        ExternalSpot.stub :fetch_hema, @raw_hema_data do
          # Stub fallbacks
          ExternalSpot.stub(:fetch_pota, []) do
            ExternalSpot.stub(:fetch_wwff, []) do
              ExternalSpot.stub(:fetch_llota, []) do
                ExternalSpot.fetch
              end
            end
          end
        end
      end
    end
    # 3. VERIFY PRODUCTION DATA INTEGRITY
    sota_spot = ExternalSpot.find_by(source_api: "SOTA", source_id: "416542")
    hema_spot = ExternalSpot.find_by(source_api: "HEMA", source_id: "36aff3626286d64d6ec4e2de23c4d632232de3413d1a1d01a42332b87d575e4c")

    # SOTA spot updated
    assert_not_nil sota_spot
    assert_equal "JO2BWZ/2", sota_spot.activatorCallsign
    assert_equal "JA/GF-199", sota_spot.code
    assert_equal "Corrected Location", sota_spot.comments
  end

end


private

# Reset the last spot_update_time so that we can send another query in test
def reset_spot_fetch_timer
  AdminSettings.first.update_column(:last_spot_read, nil)
end


