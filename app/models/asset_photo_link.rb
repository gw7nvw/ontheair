class AssetPhotoLink < ActiveRecord::Base

def photo
  p=Image.find(self.photo_id)
end
end
