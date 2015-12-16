#!/usr/bin/ruby

require "rubygems"
require "bundler"

Bundler.require

require "tilt/erb"
require "openid/store/filesystem"
require "omniauth/strategies/steam"
require "json"

class MatchTrak < Sinatra::Base
        set :sessions, true
        set :server, 'thin'
        set :sockets, []
        set :port, 3000
        set :bind, '0.0.0.0'
        api_key = "C2D4A84F12A4E7EC5FC7B6690A4530EB"
        register Sinatra::Flash
        use Rack::Session::Cookie
        @redis = Redis.new

        use OmniAuth::Builder do
          provider :steam, api_key, :storage => OpenID::Store::Filesystem.new("/tmp")
        end

        post '/' do
            payload = JSON.parse(request.body.read.to_s)
            EM.next_tick { settings.sockets.each{ |s| s.send(JSON.pretty_generate(payload)) } }
            status 200
        end

        get '/' do
            if (!request.websocket?)
                erb :index
            else
                request.websocket do |ws|
                  ws.onopen do
                    settings.sockets << ws
                  end
                  ws.onmessage do |msg|
                    EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
                  end
                  ws.onclose do
                    warn("websocket closed")
                    settings.sockets.delete(ws)
                  end
                end
            end
        end

        post '/auth/steam/callback' do
          content_type "text/plain"
          request.env["omniauth.auth"].to_hash.inspect
        end

        get '/authdata' do
            content_type "text/plain"
            request.env["omniauth.auth"].to_hash.inspect
        end

        get '/auth/failure' do

        end

        get '/js' do
            send_file 'script.js', :type => :js
        end

        # THIS ALLOWS THE SERVER TO BE STARTED DIRECTLY THROUGH RUNNING. DO NOT REMOVE #
        run! if app_file == $0
end
