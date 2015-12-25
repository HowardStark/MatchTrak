#!/usr/bin/ruby
require "bundler"
Bundler.require

require "tilt/erb"

require "openid/store/filesystem"
require "omniauth/strategies/steam"

class User < ActiveRecord::Base
    serialize :settings
end

class Team < ActiveRecord::Base
    serialize :settings
end

class MatchTrak < Sinatra::Base

    register Sinatra::Flash
    register Sinatra::ActiveRecordExtension

    use Rack::Session::Cookie, :key => 'rack.session',
                               :path => "/",
                               :secret => 'MatchTrak'

    set :protection, except: :session_hijacking
    set :server, 'thin'
    set :sockets, []
    set :port, 3000
    set :bind, '0.0.0.0'
    api_key = "C2D4A84F12A4E7EC5FC7B6690A4530EB"

    ActiveRecord::Base.establish_connection(
        :adapter  => "mysql2",
        :host     => "localhost",
        :username => "root",
        :password => "root",
        :database => "matchtrak"
    );



    use OmniAuth::Builder do
        provider :steam, api_key, :storage => OpenID::Store::Filesystem.new("/tmp")
    end

    def require_logged_in
        redirect('/auth/steam') unless is_authenticated?
    end

    def is_authenticated?
        # return false
        return !!session[:uid]
    end

    post('/') do
        payload = JSON.parse(request.body.read.to_s)
        puts "PAYLOAD: " + payload["player"]["steamid"]
        EM.next_tick {
            settings.sockets.each { |s|
                if(s[:user] == payload["player"]["steamid"])
                    s[:socket].send(JSON.pretty_generate(payload))
                end
            }
        }
        # unless payload["player"]["steamid"] != session[:uid]
        status 200
    end

    get('/debug') do
        require_logged_in
        session[:uid]
    end

    get('/logout') do
        session.clear
        redirect('/')
    end

    get('/') do
        if (!request.websocket?)
            if(is_authenticated?)
                puts session.inspect
                erb :dashboard
            else
                erb :index
            end
        else
            request.websocket do |ws|
                user = session[:uid]
                @connection = {user: user, socket: ws}
                ws.onopen do
                    settings.sockets << @connection
                end
                ws.onmessage do |msg|
                    EM.next_tick {
                        settings.sockets.each{|s|
                            if(s[:user] == user)
                                s[:socket].send(msg)
                            end
                        }
                    }
                end
                ws.onclose do
                    warn("websocket closed")
                    settings.sockets.each do |s|
                        if(s[:socket] == ws)
                            settings.sockets.delete(s)
                        end
                    end
                end
            end
        end
    end

    get('/user/:uid') do

    end

    get('/team/:tid') do

    end

    post('/auth/steam/callback') do
        content_type "text/plain"
        session[:uid] = request.env["omniauth.auth"].to_hash["uid"]
        session[:info] = request.env["omniauth.auth"].to_hash["info"]
        User.find_or_create_by(uid: session[:uid]) do |user|
            user.profileimage = session[:info]["image"]
            user.settings = {
                :private => false,
                :delay => 0
            }
        end
        redirect('/')
    end

    get('/authdata') do
        content_type "text/plain"
        session.inspect
    end

    get('/auth/failure') do

    end

    get('/js') do
        send_file 'script.js', :type => :js
    end

    # THIS ALLOWS THE SERVER TO BE STARTED DIRECTLY THROUGH RUNNING. DO NOT REMOVE #
    run! if app_file == $0
end