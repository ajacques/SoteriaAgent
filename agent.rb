#!/usr/bin/ruby
# frozen_string_literal: true
require 'docker'
require 'rest-client'
require './agent_container.rb'
require './polling_http_data_stream'
require './local_host'

if ARGV.empty?
  puts 'Not enough arguments'
  exit(-1)
end

Docker.url = ENV['DOCKER_URL'] if ENV.key? 'DOCKER_URL'
runners = { http_poll: PollingHTTPDataStream }

if ARGV[0] == 'register'
  if ARGV.size < 2
    puts 'Not enough arguments. run http://master_url'
    exit(-1)
  end
  register_url = URI(ARGV[1])

  blob = JSON.parse(RestClient.get(register_url.to_s))

  AgentContainer.register(access_token: blob['access_token'], bootstrap_url: blob['bootstrap_url'], image_name: blob['image_name'])
elsif ARGV[0] == 'run'
  bootstrap_uri = ENV['BOOTSTRAP_URL']
  bootstrap = JSON.parse(RestClient.post(bootstrap_uri, { hostname: LocalHost.name }, format: :json, authorization: "Bearer #{ENV['ACCESS_TOKEN']}"))
  puts bootstrap.inspect

  class_type = runners[bootstrap['transport'].to_sym]
  inst = class_type.new bootstrap
  inst.execute
else
  puts 'Un-recognized command'
  exit(-1)
end
