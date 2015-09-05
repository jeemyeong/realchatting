class TimelineReply < ActiveRecord::Base

    belongs_to :user 
    belongs_to :channel 
    belongs_to :timeline 
    
end
