class Timeline < ActiveRecord::Base
mount_uploader :image, TimelineImageUploader

    belongs_to :user 
    belongs_to :channel 
    has_many :timeline_replies

end
