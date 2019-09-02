# frozen_string_literal: true

require 'json'
require 'docker'
require './local_host'
require './http_req'
require './local_file_agent'

class PollingHTTPDataStream
  def initialize(bootstrap_info)
    @endpoints = bootstrap_info['endpoints']
  end

  def execute
    agent = LocalFileAgent.new
    loop do
      json = HttpApi.get_json(@endpoints['sync'])

      report = agent.process_services(json['services'])

      HttpApi.post_request(@endpoints['report'], report)

      refresh_rate = json['continuation']['refresh']
      Kernel.sleep refresh_rate.to_i
    end
  end
end
