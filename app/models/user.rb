class User < ActiveRecord::Base
  mount_uploader :image, UserImageUploader

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
has_many :channels
has_many :chat_logs
has_many :channel_joiners
has_many :timelines
has_many :timeline_replies
has_many :user_blocks
end
