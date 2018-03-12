module Processing
  # RPC call to create new transaction
  class NewTransaction
    attr_accessor :exchange, :reply_queue, :lock, :condition, :call_id, :response

    def initialize
      @exchange = Processing.channel.direct('processing')
      setup_reply_queue
    end

    def call(currency, target, amount)
      @call_id = SecureRandom.uuid

      payload = { target: target, amount: amount }.to_json
      exchange.publish(payload,
                       routing_key: currency,
                       correlation_id: call_id,
                       reply_to: reply_queue.name,
                       persistent: true)

      lock.synchronize { condition.wait(lock) }

      begin
        return JSON.parse(response, symbolize_names: true)
      rescue JSON::ParserError
        return nil
      end

    end

    private

      def setup_reply_queue
        @lock = Mutex.new
        @condition = ConditionVariable.new
        that = self
        @reply_queue = Processing.channel.queue('', exclusive: true)

        reply_queue.subscribe do |_delivery_info, properties, payload|
          if properties[:correlation_id] == that.call_id
            that.response = payload
            that.lock.synchronize { that.condition.signal }
          end
        end
      end

  end
end
