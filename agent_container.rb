# frozen_string_literal: true
class AgentContainer
  def self.register(opts = {})
    access_token = opts[:access_token]
    register_url = opts[:register_url]
    image_name = opts[:image_name]
    other_containers = opts[:container_names] || []

    env = %W(ACCESS_TOKEN=#{access_token} MASTER_URI=#{register_url})
    container = Docker::Container.create(Cmd: ['run'], Image: image_name, Binds: ['/:/host-volume'],
                                         Volumes_From: other_containers, Env: env, CapDrop: ['ALL'], Name: '/soteria-agent')
    container.start
  end
end
