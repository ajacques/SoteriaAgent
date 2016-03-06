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

      json['services'].each do |service|
        valid = certificate_valid?(service)
        unless valid
          chain = get_request(service['url'])
          save_certificate(service, chain)
        end
      end

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

  def get_request(url)
    RestClient.get(ENV['MASTER_URI'] + url, {authorization: "Bearer #{@key}"})
  end
end
