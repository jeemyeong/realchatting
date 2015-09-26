class Channel < ActiveRecord::Base
mount_uploader :image, ImageUploader

    belongs_to :user
    has_many :chat_logs
    has_many :channel_joiners
    has_many :timelines
    has_many :timeline_replies
end
