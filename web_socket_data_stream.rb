require 'websocket-client-simple'
require 'mqtt'

class WebSocketDataStream
  def initialize(bootstrap_info)
    @endpoint = bootstrap_info['endpoint']
  end

  def execute
    ws = WebSocket::Client::Simple.connect @endpoint
    ws.on :message do |msg|
      puts msg.data
    end

    ws.on :open do
      puts 'WebSocket connected'
      pkt = MQTT::Packet::Publish.new topic: 'test', payload: 'Test'
      ws.send pkt.to_s
    end

    ws.on :close do |e|
      p e
      exit 1
    end

    ws.on :error do |e|
      p e
    end

    Kernel.sleep
  end
end
