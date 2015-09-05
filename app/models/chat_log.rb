class ChatLog < ActiveRecord::Base
    belongs_to :channel
    belongs_to :user
    belongs_to :guest
end
