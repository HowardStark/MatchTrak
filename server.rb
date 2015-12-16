#!/usr/bin/ruby

require 'sinatra/base'
require 'sinatra-websocket'
require 'json'
require 'thin'
require 'tilt/erubis'
require 'omniauth'

class MatchTrak < Sinatra::Base
        set :sessions, true
        set :server, 'thin'
        set :sockets, []
        set :port, 3000
        set :bind, '0.0.0.0'

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

        get '/js' do
            send_file 'script.js', :type => :js
        end

        # THIS ALLOWS THE SERVER TO BE STARTED DIRECTLY THROUGH RUNNING. DO NOT REMOVE #
        run! if app_file == $0
end
