class HomeController < ApplicationController
    before_action :authenticate_user!, only: [:chat_maker, :chat_making, :timeline_maker, :timeline_reply_maker]
  def intro
      if ChannelJoiner.group(:channel_id).count(:id).first.nil? #접속자가 모두 0이라면
         banner_id = Channel.all.sample.id                      #배너는 하나를 샘플로 뽑자
      else
         banner_id =ChannelJoiner.group(:channel_id).count(:id).first.first #그게아니라면 접속자 1위방
      end
      @banner = Channel.where(:id => banner_id).take #현재접속자 수 1위방
      @channels = Channel.where.not(id: @banner.id)  #배너를 제외한 채널들 모음
  end
  
  def index
      if ChannelJoiner.group(:channel_id).count(:id).first.nil? #접속자가 모두 0이라면
         if ChatLog.group(:channel_id).count(:id).first.nil? #챗로그가 많이 있는 방
         banner_id = Channel.all.sample.id
         else 
         banner_id = ChatLog.group(:channel_id).count(:id).first.first
         end
      else
         banner_id = ChannelJoiner.group(:channel_id).count(:id).first.first #그게아니라면 접속자 1위방
      end
      @banner = Channel.where(:id => banner_id).take #현재접속자 수 1위방
      @channels = Channel.where.not(id: @banner.id)  #배너를 제외한 채널들 모음
      unless ChannelJoiner.where.not(updated_at: (Time.now - 30)..Time.now).take.nil?  #30초가 넘게 업데이트가 안된 db는
             ChannelJoiner.where.not(updated_at: (Time.now - 30)..Time.now).delete_all #다 지우자
      end
      
      if user_signed_in?
      else #로그인이 되어 있지 않으면
        if Guest.where(:ip_address => request.remote_ip).take.nil?   # 중복되지 않게 채크해보고
           @guest = Guest.create(ip_address: request.remote_ip)      #처음보는 ip라면 db에 저장하고 가져오고
        else
           @guest = Guest.where(:ip_address => request.remote_ip).take #봤던 ip라면 그냥 가져오고
        end
      end
      
      if user_signed_in?
        @block_user = Hash.new
        if UserBlock.where(:user_id => current_user.id, :block_guest_id => nil).take.nil?
        else
          for g in 0..UserBlock.where(:user_id => current_user.id, :block_guest_id => nil).count.to_i-1
        block_user_id = UserBlock.where(:user_id => current_user.id, :block_guest_id => nil).at(g).block_user_id
           if User.where(:id => block_user_id).take.image.thumb.url.nil?
              block_user_image = "/assets/user_image.jpg"
           else
              block_user_image = User.where(:id => params[:user_id]).take.image.thumb.url
           end
        block_user_nickname = User.where(:id => block_user_id).take.nickname
        @block_user[block_user_id] = [block_user_nickname, block_user_image]
          end
        end
        
        @block_guest = Hash.new
        if UserBlock.where(:user_id => current_user.id, :block_user_id => nil).take.nil?
        else
          for g in 0..UserBlock.where(:user_id => current_user.id, :block_user_id => nil).count.to_i-1
        block_guest_id = UserBlock.where(:user_id => current_user.id, :block_user_id => nil).at(g).block_guest_id
        block_guest_ip_address = Guest.where(:id => block_guest_id).take.ip_address.reverse[0..2]
        @block_guest[block_guest_id] = block_guest_ip_address
          end
        end

        @block_me = Array.new
        if UserBlock.where(:block_user_id => current_user.id).take.nil?
        else
          for g in 0..UserBlock.where(:block_user_id => current_user.id).count.to_i-1
        @block_me << UserBlock.where(:block_user_id => current_user.id).at(g).user.id
          end
        end
        
      else
        @block_me = Array.new
        if UserBlock.where(:block_guest_id => @guest.id).take.nil?
        else
          for g in 0..UserBlock.where(:block_guest_id => @guest.id).count.to_i-1
        @block_me << UserBlock.where(:block_guest_id => @guest.id).at(g).user.id
          end
        end
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
        render text: "<link rel='stylesheet' href='https://bootswatch.com/spacelab/bootstrap.min.css'><style type='text/css'>@import url(https://fonts.googleapis.com/earlyaccess/hanna.css);body,h1,button{font-family: 'Hanna', sans-serif;}</style>
                      <div class='container'><h1><center>챗이 삭제되었습니다.</h1><br><center><button class='btn btn-lg btn-default' onclick='self.close()'>창닫기"
      end
      
      unless ChannelJoiner.where(:channel_id => params[:id]).where.not(updated_at: (Time.now - 30)..Time.now).take.nil?  #30초가 넘게 업데이트가 안된 db는
             ChannelJoiner.where(:channel_id => params[:id]).where.not(updated_at: (Time.now - 30)..Time.now).delete_all #다 지우자
      end
      
      if user_signed_in?
        @block_user = Hash.new
        if UserBlock.where(:user_id => current_user.id, :block_guest_id => nil).take.nil?
        else
          for g in 0..UserBlock.where(:user_id => current_user.id, :block_guest_id => nil).count.to_i-1
        block_user_id = UserBlock.where(:user_id => current_user.id, :block_guest_id => nil).at(g).block_user_id
           if User.where(:id => block_user_id).take.image.thumb.url.nil?
              block_user_image = "/assets/user_image.jpg"
           else
              block_user_image = User.where(:id => params[:user_id]).take.image.thumb.url
           end
        block_user_nickname = User.where(:id => block_user_id).take.nickname
        @block_user[block_user_id] = [block_user_nickname, block_user_image]
          end
        end
        
        @block_guest = Hash.new
        if UserBlock.where(:user_id => current_user.id, :block_user_id => nil).take.nil?
        else
          for g in 0..UserBlock.where(:user_id => current_user.id, :block_user_id => nil).count.to_i-1
        block_guest_id = UserBlock.where(:user_id => current_user.id, :block_user_id => nil).at(g).block_guest_id
        block_guest_ip_address = Guest.where(:id => block_guest_id).take.ip_address.reverse[0..2]
        @block_guest[block_guest_id] = block_guest_ip_address
          end
        end

        @block_me = Array.new
        if UserBlock.where(:block_user_id => current_user.id).take.nil?
        else
          for g in 0..UserBlock.where(:block_user_id => current_user.id).count.to_i-1
        @block_me << UserBlock.where(:block_user_id => current_user.id).at(g).user.id
          end
        end
        
      else
        @block_me = Array.new
        if UserBlock.where(:block_guest_id => @guest.id).take.nil?
        else
          for g in 0..UserBlock.where(:block_guest_id => @guest.id).count.to_i-1
        @block_me << UserBlock.where(:block_guest_id => @guest.id).at(g).user.id
          end
        end
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
        guest_joiner << "<div class='guest_" + ChannelJoiner.where(:channel_id => params[:id], :user_id => nil).at(g).guest.id.to_s + " col-xs-2' style='padding:0px 0px 0px 0px;'><img src='/assets/hand.jpg' class='img-circle' style='height:30px; width:30px;'>  (" + ChannelJoiner.where(:channel_id => params[:id], :user_id => nil).at(g).guest.ip_address.reverse[0..2] + ")  <span style='font-size:10px;'>(<abbr class='timeago' title='" + guest_jointime + "'>" + guest_jointime + "</abbr>)</span></div>"
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
        user_joiner << "<div class='user_" + ChannelJoiner.where(:channel_id => params[:id], :guest_id => nil).at(g).user.id.to_s + " col-xs-2' style='padding:0px 0px 0px 0px;'><img src='" + user_image + "' class='img-circle' style='height:30px; width:30px;'><b>  " + ChannelJoiner.where(:channel_id => params[:id], :guest_id => nil).at(g).user.nickname + "</b>  <span style='font-size:10px;'>(<abbr class='timeago' title='" + user_jointime + "'>" + user_jointime + "</abbr>)</span></div>"
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
              id: cl.id.to_s,
              guest_id: "guest_" + cl.guest_id.to_s,
              nickname: "<img src='/assets/hand.jpg' class='img-circle'>  (" + Guest.where(:id => params[:guest_id]).take.ip_address.to_s.reverse[0..2] + ")  ",
              msg: params[:msg],
              count: ChatLog.where(:channel_id => params[:channel_id]).count.to_s,
              time: cl.created_at.in_time_zone("Seoul").iso8601,
              ul_open: '<ul class="dropdown-menu" aria-labelledby="dropdownMenu_' + cl.id.to_s + '">',
              li_block: '<li><a href="/home/block_guest/' + cl.guest.id.to_s + '" target="_blank">손님(' + Guest.where(:id => params[:guest_id]).take.ip_address.to_s.reverse[0..2] +') 차단하기</a></li>',
              ul_close: '<li><a href="#">Another action</a></li>
                      <li><a href="#">Something else here</a></li>
                      <li role="separator" class="divider"></li>
                      <li><a href="#">Separated link</a></li>
                    </ul>'
          })
      else
           if User.where(:id => params[:user_id]).take.image.thumb.url.nil?
              user_image = "/assets/user_image.jpg"
           else
              user_image = User.where(:id => params[:user_id]).take.image.thumb.url
           end
          WebsocketRails["chat_" + params[:id]].trigger('chat', {
              id: cl.id.to_s,
              user_id: "user_" + cl.user_id.to_s,
              nickname: "<img src='" + user_image +  "' class='img-circle'><b>  " + User.where(:id => params[:user_id]).take.nickname + "</b>  ",
              msg: params[:msg],
              count: ChatLog.where(:channel_id => params[:channel_id]).count.to_s,
              time: cl.created_at.in_time_zone("Seoul").iso8601,
              ul_open: '<ul class="dropdown-menu" aria-labelledby="dropdownMenu_' + cl.id.to_s + '">',
              li_block: '<li><a href="/home/block_user/' + cl.user.id.to_s + '" target="_blank">' + User.where(:id => params[:user_id]).take.nickname + ' 차단하기</a></li>',
              ul_close: '<li><a href="#">Another action</a></li>
                         <li><a href="#">Something else here</a></li>
                         <li role="separator" class="divider"></li>
                         <li><a href="#">Separated link</a></li>
                        </ul>'
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
                      button: ["asterisk", "plus", "minus", "cloud", "envelope", "glass", "music", "heart", "star", "film", "th-large", "th", "ok", "off", "signal", "cog", "home", "time", "road", "repeat", "lock", "flag", "headphones", "play", "leaf", "fire", "plane", "comment", "thumbs-up", "globe"].sample(1).join(''),
                      button_color: ["#2BCC4E", "#804999", "#FF9C77", "#8295FF", "#CCA699", "#CCB599", "#99887F", "#2BCC4E", "#FF726E"].sample(1).join(''),
                      image: params[:image])
      redirect_to :back
  end
  
  def timeline_reply_maker
      tl = TimelineReply.create(user_id: params[:user_id],
                                channel_id: params[:channel_id],
                                timeline_id: params[:timeline_id],
                                reply: params[:reply])
     if User.where(:id => params[:user_id]).take.image.thumb.url.nil?
        user_image = "/assets/user_image.jpg"
     else
        user_image = User.where(:id => params[:user_id]).take.image.thumb.url
     end
      WebsocketRails["timeline_" + params[:id]].trigger(params[:timeline_id] + '_reply', {
        id: tl.id,
        user_id: params[:user_id],
        image: user_image,
        nickname: User.where(:id => params[:user_id]).take.nickname,
        reply: params[:reply],
        time: tl.created_at.in_time_zone("Seoul").iso8601 
      })
      render :text => ""
  end
  
  def timeline_editor 
    @edit = Timeline.where(:id => params[:id]).take
    
  end
  
  def timeline_editing
    edit = Timeline.where(:id => params[:id]).take
      if edit.user_id == current_user.id
      edit.title = params[:title]
      edit.text = params[:text]
      edit.button = params[:button]
        unless params[:image].nil?
        edit.image = params[:image]
        end
      edit.save
      end
        render text: "<link rel='stylesheet' href='https://bootswatch.com/spacelab/bootstrap.min.css'><style type='text/css'>@import url(https://fonts.googleapis.com/earlyaccess/hanna.css);body,h1,button{font-family: 'Hanna', sans-serif;}</style>
                      <div class='container'><h1><center>게시글이 수정되었습니다.</h1><br><center><button class='btn btn-lg btn-default' onclick='self.close()'>창닫기"
  end
  
  def timeline_reply_destroying
    destroy = TimelineReply.where(:id => params[:id]).take
      if destroy.nil? #챗이 없어진경우
      else
        if destroy.user_id == current_user.id
        destroy.destroy
        end
      end
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
        render text: "<link rel='stylesheet' href='https://bootswatch.com/spacelab/bootstrap.min.css'><style type='text/css'>@import url(https://fonts.googleapis.com/earlyaccess/hanna.css);body,h1,button{font-family: 'Hanna', sans-serif;}</style>
                      <div class='container'><h1><center>챗이 수정되었습니다.</h1><br><center><button class='btn btn-lg btn-default' onclick='self.close()'>창닫기"
      end
  end
  
  def timeline_destroying
    destroy = Timeline.where(:id => params[:id]).take
      if destroy.nil? #챗이 없어진경우
      else
        if destroy.user_id == current_user.id
        destroy.destroy
        Timeline.where(:channel_id => params[:id]).all.destroy
        TimelineReply.where(:channel_id => params[:id]).all.destroy
        end
      end
        render text: "<link rel='stylesheet' href='https://bootswatch.com/spacelab/bootstrap.min.css'><style type='text/css'>@import url(https://fonts.googleapis.com/earlyaccess/hanna.css);body,h1,button{font-family: 'Hanna', sans-serif;}</style>
                      <div class='container'><h1><center>게시글이 삭제되었습니다.</h1><br><center><button class='btn btn-lg btn-default' onclick='self.close()'>창닫기"
  end
  def chat_destroying
    destroy = Channel.where(:id => params[:id]).take
      if destroy.nil? #챗이 없어진경우
      else
        if destroy.user_id == current_user.id
        destroy.destroy
        ChatLog.where(:channel_id => params[:id]).all.destroy
        ChannelJoiner.where(:channel_id => params[:id]).all.destroy
        Timeline.where(:channel_id => params[:id]).all.destroy
        TimelineReply.where(:channel_id => params[:id]).all.destroy
        end
      end
        render text: "<link rel='stylesheet' href='https://bootswatch.com/spacelab/bootstrap.min.css'><style type='text/css'>@import url(https://fonts.googleapis.com/earlyaccess/hanna.css);body,h1,button{font-family: 'Hanna', sans-serif;}</style>
                      <div class='container'><h1><center>챗이 삭제되었습니다.</h1><br><center><button class='btn btn-lg btn-default' onclick='self.close()'>창닫기"
  end
  
  def block_user
    @user = User.where(:id => params[:id]).take
  end
  
  def block_guest
    @guest = Guest.where(:id => params[:id]).take
  end
  
  def blocking_user
    if UserBlock.where(:user_id => params[:user_id], :block_user_id => params[:id]).take.nil?
       UserBlock.create(user_id: params[:user_id], block_user_id: params[:id])
    end
        render text: "<link rel='stylesheet' href='https://bootswatch.com/spacelab/bootstrap.min.css'><style type='text/css'>@import url(https://fonts.googleapis.com/earlyaccess/hanna.css);body,h1,button{font-family: 'Hanna', sans-serif;}</style>
                      <div class='container'><h1><center> 차단했습니다.</h1><br><center><button class='btn btn-lg btn-default' onclick='self.close()'>창닫기"
        
         if User.where(:id => params[:id]).take.image.thumb.url.nil?
            user_image = "/assets/user_image.jpg"
         else
            user_image = User.where(:id => params[:id]).take.image.thumb.url
         end
        WebsocketRails["block"].trigger('block', {
              user_id: params[:user_id],
              block_user_id: params[:id],
              block_user_image: user_image,
              block_user_nickname: User.where(:id => params[:id]).take.nickname
              
          })
  end
  def blocking_guest
    if UserBlock.where(:user_id => params[:user_id], :block_guest_id => params[:id]).take.nil?
       UserBlock.create(user_id: params[:user_id], block_guest_id: params[:id])
    end
        render text: "<link rel='stylesheet' href='https://bootswatch.com/spacelab/bootstrap.min.css'><style type='text/css'>@import url(https://fonts.googleapis.com/earlyaccess/hanna.css);body,h1,button{font-family: 'Hanna', sans-serif;}</style>
                      <div class='container'><h1><center> 차단했습니다.</h1><br><center><button class='btn btn-lg btn-default' onclick='self.close()'>창닫기"
                      
        WebsocketRails["block"].trigger('block', {
              user_id: params[:user_id],
              block_guest_id: params[:id],
              block_guest_ip_address: Guest.where(:id => params[:id]).take.ip_address.to_s.reverse[0..2]
          })
  end
  
  def unblock_user
    @user = User.where(:id => params[:id]).take
  end
  
  def unblock_guest
    @guest = Guest.where(:id => params[:id]).take
  end
  
  def unblocking_user
    unless UserBlock.where(:user_id => params[:user_id], :block_user_id => params[:id]).take.nil?
           UserBlock.where(:user_id => params[:user_id], :block_user_id => params[:id]).take.destroy
    end
        render text: "<link rel='stylesheet' href='https://bootswatch.com/spacelab/bootstrap.min.css'><style type='text/css'>@import url(https://fonts.googleapis.com/earlyaccess/hanna.css);body,h1,button{font-family: 'Hanna', sans-serif;}</style>
                      <div class='container'><h1><center> 차단해제되었습니다.</h1><br><center><button class='btn btn-lg btn-default' onclick='self.close()'>창닫기"
                      
        WebsocketRails["block"].trigger('unblock', {
              user_id: params[:user_id],
              block_user_id: params[:id]
          })
  end
  
  def unblocking_guest
    unless UserBlock.where(:user_id => params[:user_id], :block_guest_id => params[:id]).take.nil?
           UserBlock.where(:user_id => params[:user_id], :block_guest_id => params[:id]).take.destroy
    end
        render text: "<link rel='stylesheet' href='https://bootswatch.com/spacelab/bootstrap.min.css'><style type='text/css'>@import url(https://fonts.googleapis.com/earlyaccess/hanna.css);body,h1,button{font-family: 'Hanna', sans-serif;}</style>
                      <div class='container'><h1><center> 차단해제되었습니다.</h1><br><center><button class='btn btn-lg btn-default' onclick='self.close()'>창닫기"
                      
        WebsocketRails["block"].trigger('unblock', {
              user_id: params[:user_id],
              block_guest_id: params[:id]
          })
  end
  
end
