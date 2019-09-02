#!/usr/bin/ruby
# frozen_string_literal: true

require 'docker'
require './agent_container.rb'
require './polling_http_data_stream'
require './local_host'
require './http_req'

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

  blob = HttpApi.get_json(register_url)

  AgentContainer.register(access_token: blob['access_token'], bootstrap_url: blob['bootstrap_url'], image_name: blob['image_name'])
elsif ARGV[0] == 'run'
  bootstrap_uri = ENV['BOOTSTRAP_URL']
  bootstrap = HttpApi.post_json(bootstrap_uri, hostname: LocalHost.name)
  puts bootstrap.inspect

  class_type = runners[bootstrap['transport'].to_sym]
  inst = class_type.new bootstrap
  inst.execute
else
  puts 'Un-recognized command'
  exit(-1)
end
