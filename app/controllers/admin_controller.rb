class AdminController < ApplicationController
    before_action :authenticate_admin!
  def channels
    @channels = Channel.all
  end
  def channel
    @chatlogs = ChatLog.where(:channel_id => params[:id]).all
  end
  
  def channel_edit
    @channel = Channel.find(params[:id])
  end
  
  def channel_editing
    edit = Channel.find(params[:id])
      edit.user_id = params[:user_id]
      edit.title = params[:title]
      unless params[:image].nil?
      edit.image = params[:image]
      end
      edit.mediatype = params[:mediatype]
      edit.save
    redirect_to '/admin/channels'
  end
  
  def channel_destroy
    Channel.find(params[:id]).destroy
    ChatLog.where(:channel_id => params[:id]).all.destroy
    ChannelJoiner.where(:channel_id => params[:id]).all.destroy
    Timeline.where(:channel_id => params[:id]).all.destroy
    TimelineReply.where(:channel_id => params[:id]).all.destroy
    redirect_to :back
  end
  
  def channel_update
    uri = URI("http://tvcast.naver.com/t/all/popular")
    html_doc = Nokogiri::HTML(Net::HTTP.get(uri))
    
    for g in 0..99
      if html_doc.css("div.daily_list//strong")[g].nil?
        break
      end
      title = html_doc.css("div.daily_list//strong")[g].inner_text
      if Channel.where(:user_id => "0", :title => title).take.nil?
        channel = Channel.new
        channel.user_id = "0"
        channel.title = title
      else
        channel = Channel.where(:user_id => "0", :title => title).take
      end
          playlist = URI(html_doc.css("div.daily_list//a")[2*g]['href'])
          playlist_doc = Nokogiri::HTML(Net::HTTP.get(playlist))
            unless playlist_doc.css("div#container//img")[0].nil?
              if channel.image.url.nil?
              image = playlist_doc.css("div#container//img")[0]['src']
              channel.remote_image_url = image
              end
            end
            unless playlist_doc.css("a.btn_all")[0].nil?
            play = playlist_doc.css("a.btn_all")[0]['href']
            channel.play = play
            end
            unless playlist_doc.css("dl.tit_ar//a")[0].nil?
            link = playlist_doc.css("dl.tit_ar//a")[0]['href']
            channel.link = link
            end
            for i in 0..99
              if html_doc.css("div.col1//strong")[i].nil?
                break
              end
              if title == html_doc.css("div.col1//strong")[i].inner_text
                channel.monday = true
              end
              if title == html_doc.css("div.col2//strong")[i].inner_text
                channel.tuesday = true
              end
              if title == html_doc.css("div.col3//strong")[i].inner_text
                channel.wednesday = true
              end
              if title == html_doc.css("div.col4//strong")[i].inner_text
                channel.thursday = true
              end
              if title == html_doc.css("div.col5//strong")[i].inner_text
                channel.friday = true
              end
              if title == html_doc.css("div.col6//strong")[i].inner_text
                channel.saturday = true
              end
              if title == html_doc.css("div.col7//strong")[i].inner_text
                channel.sunday = true
              end
            end
        channel.save
    @channel = Channel.all
    end
  end
  
  def users
    @users = User.all
  end
  
  def user_destroy
    User.find(params[:id]).destroy
    ChatLog.where(:user_id => params[:id]).all.destroy
    ChannelJoiner.where(:user_id => params[:id]).all.destroy
    Timeline.where(:user_id => params[:id]).all.destroy
    TimelineReply.where(:user_id => params[:id]).all.destroy
    redirect_to :back
  end
  
end
