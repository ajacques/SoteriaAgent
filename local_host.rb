# frozen_string_literal: true

class LocalHost
  def self.path(name)
    "/host-volume#{name}"
  end

  def self.name
    File.read(path('/etc/hostname')).strip
  end
end
