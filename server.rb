#!/usr/bin/ruby

require 'sinatra'
require 'sinatra-websocket'
require 'json'
require 'thin'
require 'tilt/erubis'

set :server, 'thin'
set :sockets, []
set :port, 3000
set :bind, '0.0.0.0'

@@data = '{"content": "Error: no data has been passed by CS:GO"}'

post '/' do
    payload = JSON.parse(request.body.read.to_s)
    puts "####################"
    puts JSON.pretty_generate(payload)
    puts "####################"
    @@data = payload
    EM.next_tick { settings.sockets.each{|s| s.send(JSON.pretty_generate(payload)) } }
    status 200
end

get '/api/player' do
    content_type :json
    JSON.pretty_generate(@@data)
end

get '/' do
    @weapon = "Weapon Unavailable"
    @ammos = Hash.new("Ammo Unavailable")
    @health = "Health Unavailable"
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