class AdminController < ApplicationController
    before_action :authenticate_admin!, only: [:channels, :channel_edit, :channel_editing, :channel_destroy]
  def channels
    @channels = Channel.all
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
