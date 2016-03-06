require 'json'
require 'rest-client'

class PollingHTTPDataStream
  def initialize(bootstrap_info)
    @endpoints = bootstrap_info['endpoints']
    @key = ENV['ACCESS_TOKEN']
  end

  def execute
    while true
      puts 'Requesting'
      json = JSON.parse(get_request(@endpoints['sync']))

      report = {}
      json['services'].each do |service|
        valid = certificate_valid?(service)
        cert_report = {}
        cert_report['changed'] = !valid
        unless valid
          chain = get_request(service['url'])
          save_certificate(service, chain)
          post_rotation(service)
        end
        report[service['id']] = cert_report
      end

      post_request(@endpoints['report'], report)

      refresh_rate = json['continuation']['refresh']
      Kernel.sleep refresh_rate.to_i
    end
  end

  private

  def certificate_valid?(service)
    if File.exist? service['path']
      actual = Digest::SHA256.file service['path']
      service['hash']['value'] == actual.to_s
    else
      false
    end
  end

  def save_certificate(service, certificate)
    File.open(service['path'], 'w') do |file|
      file.write(certificate)
    end
    File.chmod(0600, service['path'])
  end

  def post_rotation(service)
    return unless service.has_key? 'after_action'
    service['after_action'].each do |action|
      if action['type'] == 'docker'
        container = Docker::Container.get(action['container_name'])
        if action.has_key? 'signal'
          container.kill!(Signal: action['signal'])
        else
          #container.restart!
        end
      end
    end
  end

  def get_request(url)
    RestClient.get(ENV['MASTER_URI'] + url, {authorization: "Bearer #{@key}"})
  end

  def post_request(url, body)
    RestClient.post(ENV['MASTER_URI'] + url, body.to_json, {authorization: "Bearer #{@key}", content_type: :json})
  end
end
