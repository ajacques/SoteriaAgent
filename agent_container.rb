# frozen_string_literal: true
class AgentContainer
  def self.register(access_token:, bootstrap_url:, image_name:, other_containers: [])
    env = %W(BOOTSTRAP_URL=#{bootstrap_url} ACCESS_TOKEN=#{access_token})
    container = Docker::Container.create(Cmd: ['run'], Image: image_name, Binds: ['/:/host-volume'],
                                         Volumes_From: other_containers, Env: env, CapDrop: ['ALL'], Name: '/soteria-agent')
    container.start
  end
end
