#!/usr/bin/ruby
require 'docker'
require 'rest-client'
require 'websocket-client-simple'
require 'mqtt'

if ARGV.size == 0
  puts 'Not enough arguments'
  exit -1
end

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
  bootstrap = JSON.parse(RestClient.get(bootstrap_uri, {format: :json}))
  puts bootstrap.inspect


  Kernel.sleep
end
