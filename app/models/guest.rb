class Guest < ActiveRecord::Base
    has_many :chat_logs
    has_many :channel_joiners
end
