# frozen_string_literal: true
require 'json'
require 'rest-client'

class PollingHTTPDataStream
  def initialize(bootstrap_info)
    @endpoints = bootstrap_info['endpoints']
    @key = ENV['ACCESS_TOKEN']
  end

  def execute
    loop do
      json = JSON.parse(get_request(@endpoints['sync']))

      report = {}
      json['services'].each do |service|
        report[service['id']] = process_certificate_directive(service)
      end

      post_request(@endpoints['report'], report)

      refresh_rate = json['continuation']['refresh']
      Kernel.sleep refresh_rate.to_i
    end
  end

  private

  def process_certificate_directive(service)
    valid = certificate_valid?(service)
    unless valid
      chain = get_request(service['url'])
      begin
        save_certificate(service, chain)
        post_rotation(service)
      rescue StandardError => ex
        return failed_report(ex)
      end
    end
    succeeded_report
  end

  def succeeded_report
    {
      state: :valid
    }
  end

  def failed_report(error)
    {
      state: :failed,
      reason: {
        class: error.class.name,
        message: error.message
      }
    }
  end

  def certificate_valid?(service)
    return false unless File.exist? qualified_cert_filename(service)
    actual = Digest::SHA256.file qualified_cert_filename(service)
    service['hash']['value'] == actual.to_s
  end

  def qualified_cert_filename(service)
    "/host-volume#{service['path']}"
  end

  def save_certificate(service, certificate)
    file_name = qualified_cert_filename(service)
    File.open(file_name, 'w') do |file|
      file.write(certificate)
    end
    File.chmod(0o600, file_name)
  end

  def post_rotation(service)
    return unless service.key? 'after_action'
    service['after_action'].each do |action|
      if action['type'] == 'docker'
        container = Docker::Container.get(action['container_name'])
        container.kill!(Signal: action['signal']) if action.key? 'signal'
      end
    end
  end

  def get_request(url)
    RestClient.get(url, authorization: "Bearer #{@key}")
  end

  def post_request(url, body)
    RestClient.post(url, body.to_json, authorization: "Bearer #{@key}", content_type: :json)
  end
end
