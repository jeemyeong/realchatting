class ChannelJoiner < ActiveRecord::Base
    belongs_to :user 
    belongs_to :channel    
    belongs_to :guest    
end
