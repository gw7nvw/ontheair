# frozen_string_literal: true

# typed: false
class AssetPhotoLink < ActiveRecord::Base
  def photo
    Image.find(photo_id)
  end
end
