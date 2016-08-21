# frozen_string_literal: true

module LocalHost
  def path(name)
    "/host-volume#{name}"
  end

  def name
    File.read(path('/etc/hostname'))
  end
end
