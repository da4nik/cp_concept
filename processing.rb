require 'bunny'
require 'securerandom'
require 'json'

class ProcessingServer
  def initialize(_currency)
    @currency = _currency
    @connection = Bunny.new
    @connection.start
    @channel = @connection.create_channel
    @event_queue = @channel.queue('events', durable: true)
  end

  def start
    @response_exchange = @channel.default_exchange
    @exchange = @channel.direct('processing')
    @queue = channel.queue('', exclusive: true)
    @queue.bind(@exchange, routing_key: currency)

    subscribe_to_queue
  end

  def stop
    @channel.close
    @connection.close
  end

  private

    attr_reader :channel, :exchange, :connection, :queue,
                :response_exchange, :currency, :event_queue

    def subscribe_to_queue
      queue.subscribe(block: true) do |_delivery_info, properties, data|
        response = { errors: [] }
        payload = nil
        begin
          payload = JSON.parse(data, symbolize_names: true)
        rescue JSON::ParserError => e
          response[:errors] << "Params parsing error: #{e.message}"
        end

        puts " [*] Got the data: #{ payload.inspect }"

        payload[:amount] = payload[:amount].to_i

        if payload[:amount].nil? || payload[:amount].zero?
          response[:errors] << 'Nothing to transfer'
        end

        if payload[:target].nil? || payload[:target].size.zero?
          response[:errors] << 'Nowhere to transfer'
        end

        if response[:errors].size.zero?
          response[:transaction_id] = SecureRandom.uuid
        end

        response_exchange.publish(response.to_json,
                                  routing_key: properties.reply_to,
                                  correlation_id: properties.correlation_id)
        event = {
            currency: currency,
            source: payload[:source],
            target: payload[:target],
            amount: payload[:amount].to_i,
            transaction_id: response[:transaction_id]
        }
        event_queue.publish(event.to_json, persestent: true)
      end
    end

end

puts ARGV.inspect

begin
  server = ProcessingServer.new(ARGV[0])

  server.start
rescue Interrupt => _
  server.stop
end
