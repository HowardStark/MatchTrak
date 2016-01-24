require 'rails_helper'

RSpec.describe SteamCallbackController, type: :controller do
  let(:uid) { "76561198010202071" } 
  let(:nickname) { 'Dude Duderson' }
  let(:image) { 'http://www.steam.com/volvo/plz/gabe.png' }
  let(:omniauth_payload) {{
  :provider => "steam",
  :uid => uid,
  :info => {
    :nickname => nickname,
    :name => "Rodrigo Navarro",
    :location => "BR",
    :image => image,
    :urls => {
      :Profile => "http://steamcommunity.com/id/rnavarro1/"
    }
  },
  :credentials => {},
  :extra => {
    :raw_info => {
      :steamid => "76561198010202071",
      :communityvisibilitystate => 3,
      :profilestate => 1,
      :personaname => "Reu",
      :lastlogoff => 1325637158,
      :profileurl => "http://steamcommunity.com/id/rnavarro1/",
      :avatar => "http://media.steampowered.com/steamcommunity/public/images/avatars/3c/3c91a935dca0c1e243f3a67a198b0abea9cf6d48.jpg",
      :avatarmedium => "http://media.steampowered.com/steamcommunity/public/images/avatars/3c/3c91a935dca0c1e243f3a67a198b0abea9cf6d48_medium.jpg",
      :avatarfull => "http://media.steampowered.com/steamcommunity/public/images/avatars/3c/3c91a935dca0c1e243f3a67a198b0abea9cf6d48_full.jpg",
      :personastate => 1,
      :realname => "Rodrigo Navarro",
      :primaryclanid => "103582791432706194",
      :timecreated => 1243031082,
      :loccountrycode => "BR"
    }
  }
}}

  describe 'auth_user' do
    before do
      request.env['omniauth.auth'] = omniauth_payload
    end

    it 'finds a user matching the uid if they exist and assigns them to @user' do
      steam_user = User.create(uid: uid)

      allow(User).to receive(:where).and_call_original
 
      post :auth_user

      expect(User).to have_received(:where).with(uid: uid.to_i)
      expect(assigns(:user)).to eq(steam_user)
    end

    it 'creates a user with the uid if they do not exist' do
      expect(User.where(uid: uid.to_i).first).to be_nil

      post :auth_user

      found_user = User.where(uid: uid.to_i).first

      expect(found_user.nickname).to eq(nickname)
      expect(found_user.image).to eq(image)
    end

    it 'adds the uid to the session' do
      post :auth_user

      expect(session[:uid]).to eq(uid.to_i)
    end

    it 'raises a 500 error if no uid is included' do
      request.env['omniauth.auth'].delete(:uid)

      response = post :auth_user
    
      expect(response.code).to eq('500')
      expect(assigns(:user)).to be_nil
    end

    it 'redirects to the users dashboard' do
      expect(post :auth_user).to redirect_to(dashboard_path)
    end
  end
end
