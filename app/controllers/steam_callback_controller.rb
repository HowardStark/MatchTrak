class SteamCallbackController < ApplicationController
  before_filter :set_steam_userid

  def auth_user
    session[:uid] = @steam_userid

    unless @user = User.where(uid: @steam_userid).first
      @user = User.create(uid: @steam_userid, 
                          nickname: omniauth_payload[:info][:nickname],
                          image: omniauth_payload[:info][:image])
    end
    redirect_to dashboard_path
  end

  private
 
  def set_steam_userid
    @steam_userid = omniauth_payload[:uid].present? && omniauth_payload[:uid].to_i
    raise MissingUid unless @steam_userid.is_a?(Fixnum)
  rescue MissingUid
    render plain: "OK", status: 500
  end

  def omniauth_payload
    @omniauth_payload ||= request.env['omniauth.auth']
  end
end

class MissingUid < StandardError
end
