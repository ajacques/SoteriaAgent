# frozen_string_literal: true

class LocalFileAgent
  def process_services(services)
    service_reports = {}
    report = {
      hostname: LocalHost.name,
      services: service_reports
    }
    services.each do |service|
      service_reports[service['id']] = process_certificate_directive(service)
    end
    report
  end

  def process_certificate_directive(service)
    valid = certificate_valid?(service)
    if valid
      succeeded_report
    else
      deploy_certificate(service)
    end
  end

  def deploy_certificate(service)
    chain = HttpApi.get_request(service['url'])
    begin
      save_certificate(service, chain)
      post_rotation(service)
    rescue StandardError => ex
      puts ex
      failed_report(ex)
    end
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
    LocalHost.path(service['path'])
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
end
