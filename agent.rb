#!/usr/bin/ruby
require 'docker'
require 'rest-client'
require './agent_container.rb'
require './web_socket_data_stream'
require './polling_http_data_stream'

if ARGV.size == 0
  puts 'Not enough arguments'
  exit -1
end

Docker.url = ENV['DOCKER_URL'] if ENV.key? 'DOCKER_URL'
runners = {websocket: WebSocketDataStream, http_poll: PollingHTTPDataStream}

if ARGV[0] == 'register'
  if ARGV.size < 2
    puts 'Not enough arguments. run http://master_uri'
    exit -1
  end
  register_url = URI(ARGV[1])
  master_url = URI("#{register_url.scheme}://#{register_url.host}:#{register_url.port}")

  blob = JSON.parse(RestClient.get(register_url.to_s))

  AgentContainer.register(access_token: blob['access_token'], master_url: register_url, image_name: blob['image_name'])
elsif ARGV[0] == 'run'
  bootstrap_uri = "#{ENV['MASTER_URI']}/agents/bootstrap?token=#{ENV['ACCESS_TOKEN']}"
  bootstrap = JSON.parse(RestClient.get(bootstrap_uri, {format: :json, authorization: "Bearer #{ENV['ACCESS_TOKEN']}"}))
  puts bootstrap.inspect

  class_type = runners[bootstrap['transport'].to_sym]
  inst = class_type.new bootstrap
  inst.execute
else
  puts 'Un-recognized command'
  exit - 1
end
