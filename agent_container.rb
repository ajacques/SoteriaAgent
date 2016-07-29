# frozen_string_literal: true
class AgentContainer
  def self.register(access_token:, bootstrap_url:, image_name:, other_containers: [])
    env = %W(BOOTSTRAP_URL=#{bootstrap_url} ACCESS_TOKEN=#{access_token})
    container = Docker::Container.create(Cmd: ['run'], Image: image_name, Binds: ['/:/host-volume'],
                                         Volumes_From: other_containers, Env: env, CapDrop: ['ALL'], CapAdd: capabilities, Name: '/soteria-agent')
    container.start
  end

  private

  def capabilities
    # Since the agent runs as root, we use this permission to ignore file owner/groups
    ['DAC_OVERRIDE']
  end
end
