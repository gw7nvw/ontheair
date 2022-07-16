class UpdateSotaActivations
  @queue = :ota_scheduled

  def self.perform()   
    puts "UPDATE_SOTA_ACTIVATIONS: Got called"
    as=AdminSettings.last
    if !as.last_sota_activation_update_at or (as.last_sota_activation_update_at+30.days)<=Time.now() then
      as.last_sota_activation_update_at=Time.now()
      as.save
      SotaActivation.import
    end
  end
end
  