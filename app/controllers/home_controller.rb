class HomeController < ApplicationController
    before_action :authenticate_user!, only: [:chat_maker, :chat_making, :timeline_maker, :timeline_reply_maker]
  def intro
      if Channel.take.nil?                                    #채널에방이 아무것도 없다면
         Channel.create(:user_id => "0", :title => "default") #user_id 0인 default채널을 하나 만들자.
      end
      if ChannelJoiner.group(:channel_id).count(:id).first.nil? #접속자가 모두 0이라면
         banner_id = Channel.all.sample.id                      #배너는 하나를 샘플로 뽑자
      else
         banner_id =ChannelJoiner.group(:channel_id).count(:id).first.first #그게아니라면 접속자 1위방
      end
      @banner = Channel.where(:id => banner_id).take #현재접속자 수 1위방
      @channels = Channel.where.not(id: @banner.id)  #배너를 제외한 채널들 모음
  end
  
  def index
      if Channel.take.nil?                                    #채널에방이 아무것도 없다면
         Channel.create(:user_id => "0", :title => "default") #user_id 0인 default채널을 하나 만들자.
      end
      if ChannelJoiner.group(:channel_id).count(:id).first.nil? #접속자가 모두 0이라면
         banner_id = Channel.all.sample.id                      #배너는 하나를 샘플로 뽑자
      else
         banner_id =ChannelJoiner.group(:channel_id).count(:id).first.first #그게아니라면 접속자 1위방
      end
      @banner = Channel.where(:id => banner_id).take #현재접속자 수 1위방
      @channels = Channel.where.not(id: @banner.id)  #배너를 제외한 채널들 모음
      unless ChannelJoiner.where.not(updated_at: (Time.now - 30)..Time.now).take.nil?  #30초가 넘게 업데이트가 안된 db는
             ChannelJoiner.where.not(updated_at: (Time.now - 30)..Time.now).delete_all #다 지우자
      end
  end
  
  def chat
      @channel = Channel.where(:id => params[:id]).take
        if user_signed_in? #로그인이 되어 있으면
          if ChannelJoiner.where(:channel_id => params[:id], :user_id => current_user.id).take.nil? # 중복되지 않게 체크하고
             ChannelJoiner.create(user_id: current_user.id, channel_id: params[:id], guest_id: nil) # joiner에 current_user.id를 저장하자
          end
        else #로그인이 되어 있지 않으면
          if Guest.where(:ip_address => request.remote_ip).take.nil?   # 중복되지 않게 채크해보고
             @guest = Guest.create(ip_address: request.remote_ip)      #처음보는 ip라면 db에 저장하고 가져오고
          else
             @guest = Guest.where(:ip_address => request.remote_ip).take #봤던 ip라면 그냥 가져오고
          end
          
          if ChannelJoiner.where(:channel_id => params[:id], :guest_id => @guest.id).take.nil? #중복되지 않게 체크하고
             ChannelJoiner.create(channel_id: params[:id], guest_id: @guest.id, user_id: nil) #joiner에 게스트 id를 저장하자
          end
        end
                 @channel_user_joiner = Array.new
          unless ChannelJoiner.where(:channel_id => params[:id], :guest_id => nil).take.nil? #로그인접속자가 있다면 뽑아오자
                 @channel_user_joiner = ChannelJoiner.where(:channel_id => params[:id], :guest_id => nil).all
          end
                 @channel_guest_joiner = Array.new
          unless ChannelJoiner.where(:channel_id => params[:id], :user_id => nil).take.nil? #게스트접속자가 있다면 뽑아오자
                 @channel_guest_joiner = ChannelJoiner.where(:channel_id => params[:id], :user_id => nil).all
          end
      if @channel.nil? #챗이 없어진경우
        render text: "<link rel='stylesheet' href='https://bootswatch.com/flatly/bootstrap.min.css'>
                      <div class='container'><h1><center>챗이 삭제되었습니다.</h1><br><center><button class='btn btn-lg btn-default' onclick='self.close()'>창닫기"
      end
      
      unless ChannelJoiner.where(:channel_id => params[:id]).where.not(updated_at: (Time.now - 30)..Time.now).take.nil?  #30초가 넘게 업데이트가 안된 db는
             ChannelJoiner.where(:channel_id => params[:id]).where.not(updated_at: (Time.now - 30)..Time.now).delete_all #다 지우자
      end
  end
  
  def channel_joiners
      if params[:user_id].nil? #게스트에 대한 데이터라면
         update = ChannelJoiner.where(:channel_id => params[:id], :guest_id => params[:guest_id]).take
         update.updated_at = Time.now
         update.save #게스트를 찾아서 업데이트 
       else #유져에 대한 데이터라면
         update = ChannelJoiner.where(:channel_id => params[:id], :user_id => params[:user_id]).take
         update.updated_at = Time.now
         update.save #유져를 찾아서 업데이트
      end
      
      unless ChannelJoiner.where(:channel_id => params[:id]).where.not(updated_at: (Time.now - 30)..Time.now).take.nil?  #30초가 넘게 업데이트가 안된 db는
             ChannelJoiner.where(:channel_id => params[:id]).where.not(updated_at: (Time.now - 30)..Time.now).delete_all #다 지우자
      end
      
      guest_joiner = Array.new
      if ChannelJoiner.where(:channel_id => params[:id], :user_id => nil).count.to_i == 0
         guest_nickname = " "
      else
        for g in 0..ChannelJoiner.where(:channel_id => params[:id], :user_id => nil).count.to_i-1
        guest_jointime = ChannelJoiner.where(:channel_id => params[:id], :user_id => nil).at(g).created_at.in_time_zone("Seoul").iso8601 
        guest_joiner << "<img src='/assets/hand.jpg' class='img-circle' style='height:30px; width:30px;'>손님(" + ChannelJoiner.where(:channel_id => params[:id], :user_id => nil).at(g).guest.ip_address.reverse[0..2] + ")<span style='font-size:10px;'>(<abbr class='timeago' title='" + guest_jointime + "'>" + guest_jointime + "</abbr>)</span>"
        guest_nickname = guest_joiner.join(' ')
        end
      end
      
      user_joiner = Array.new
      if ChannelJoiner.where(:channel_id => params[:id], :guest_id => nil).count.to_i == 0
         user_nickname = " "
      else
        for g in 0..ChannelJoiner.where(:channel_id => params[:id], :guest_id => nil).count.to_i-1
           if ChannelJoiner.where(:channel_id => params[:id], :guest_id=> nil).at(g).user.image.thumb.url.nil?
              user_image = "/assets/user_image.jpg"
           else
              user_image = ChannelJoiner.where(:channel_id => params[:id], :guest_id=> nil).at(g).user.image.thumb.url
           end
        user_jointime = ChannelJoiner.where(:channel_id => params[:id], :guest_id => nil).at(g).created_at.in_time_zone("Seoul").iso8601 
        user_joiner << "<img src='" + user_image + "' class='img-circle' style='height:30px; width:30px;'><b>" + ChannelJoiner.where(:channel_id => params[:id], :guest_id => nil).at(g).user.nickname + "</b><span style='font-size:10px;'>(<abbr class='timeago' title='" + user_jointime + "'>" + user_jointime + "</abbr>)</span>"
        user_nickname = user_joiner.join(' ')
        end
      end
      
      WebsocketRails["user_" + params[:id]].trigger('chat', { #웹소켓으로 쏴버린다.
          user_nickname: user_nickname,
          guest_nickname: guest_nickname,
          count: ChannelJoiner.where(:channel_id => params[:id], :user_id => nil).count.to_i + ChannelJoiner.where(:channel_id => params[:id], :guest_id => nil).count.to_i,
          time: Time.now.in_time_zone("Seoul").to_s
      })
          render text: ""
  end
  
  
  def send_msg
    
      cl = ChatLog.create(user_id: params[:user_id],
                          channel_id: params[:channel_id],
                          guest_id: params[:guest_id],
                          msg: params[:msg])
      
      if params[:user_id].nil?
          WebsocketRails["chat_" + params[:id]].trigger('chat', {
              nickname: "<img src='/assets/hand.jpg' class='img-circle' style='height:30px; width:30px;'>(" + Guest.where(:id => params[:guest_id]).take.ip_address.to_s.reverse[0..2] + ")",
              msg: params[:msg],
              count: ChatLog.where(:channel_id => params[:channel_id]).count.to_s,
              time: cl.created_at.in_time_zone("Seoul").iso8601
          })
      else
           if User.where(:id => params[:user_id]).take.image.thumb.url.nil?
              user_image = "/assets/user_image.jpg"
           else
              user_image = User.where(:id => params[:user_id]).take.image.thumb.url
           end
          WebsocketRails["chat_" + params[:id]].trigger('chat', {
              nickname: "<img src='" + user_image +  "' class='img-circle' style='height:30px; width:30px;'><b>" + User.where(:id => params[:user_id]).take.nickname + "</b>",
              msg: params[:msg],
              count: ChatLog.where(:channel_id => params[:channel_id]).count.to_s,
              time: cl.created_at.in_time_zone("Seoul").iso8601 
          })
      end
    
        
      render :text => ""
  end
  
  def chat_maker
  end
  
  def timeline_maker
    Timeline.create(user_id: current_user.id,
                    channel_id: params[:id],
                    title: params[:title],
                    text: params[:text],
                    button: params[:button],
                    image: params[:image])
      redirect_to :back
  end
  
  def timeline_reply_maker
    TimelineReply.create(user_id: current_user.id,
                         channel_id: params[:id],
                         timeline_id: params[:timeline],
                         reply: params[:reply])
     redirect_to :back
  end
  
  def chat_making
    Channel.create(user_id: current_user.id,
                   title: params[:title],
                  image: params[:image])
    redirect_to '/'
  end
  
  def chat_editing
    edit = Channel.where(:id => params[:id]).take
      if edit.user_id == current_user.id
      edit.title = params[:title]
        unless params[:image].nil?
        edit.image = params[:image]
        end
      edit.save
      end
    redirect_to '/'
  end
  
  def chat_destroying
    destroy = Channel.where(:id => params[:id]).take
      if destroy.nil? #챗이 없어진경우
        render text: "<link rel='stylesheet' href='https://bootswatch.com/flatly/bootstrap.min.css'>
                      <div class='container'><h1><center>챗이 삭제되었습니다.</h1><br><center><button class='btn btn-lg btn-default' onclick='self.close()'>창닫기"
      else
        if destroy.user_id == current_user.id
        destroy.destroy
        ChatLog.where(:channel_id => params[:id]).all.destroy
        ChannelJoiner.where(:channel_id => params[:id]).all.destroy
        end
      end
  end
  
  def type_edit
    edit = Channel.find(params[:id])
    edit.mediatype = params[:mediatype]
    edit.save
  end
end
