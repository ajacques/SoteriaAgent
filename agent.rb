#!/usr/bin/ruby
require 'docker'
require 'rest-client'
require './web_socket_data_stream'
require './polling_http_data_stream'

if ARGV.size == 0
  puts 'Not enough arguments'
  exit -1
end

runners = {websocket: WebSocketDataStream, http_poll: PollingHTTPDataStream}

if ARGV[0] == 'register'
  if ARGV.size < 2
    puts 'Not enough arguments. run http://master_uri'
    exit -1
  end

  Docker.url = 'http://docker.devvm'
  blob = JSON.parse(RestClient.get(ARGV[1]))

  env = %W(ACCESS_TOKEN=#{blob['access_token']} BOOTSTRAP_URI=http://certmgr.devvm/agents/bootstrap)
  container = Docker::Container.create(Cmd: ['run'], Image: 'soteria-agent',  Env: env, CapDrop: ['ALL'], Name: '/soteria-agent')
  container.start
elsif ARGV[0] == 'run'
  bootstrap_uri = "#{ENV['BOOTSTRAP_URI']}?token=#{ENV['ACCESS_TOKEN']}"
  bootstrap = JSON.parse(RestClient.get(bootstrap_uri, {format: :json, authorization: "Bearer #{ENV['ACCESS_TOKEN']}"}))
  puts bootstrap.inspect

  class_type = runners[bootstrap['transport'].to_sym]
  inst = class_type.new bootstrap
  inst.execute
end
