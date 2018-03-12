namespace :worker do
  desc 'Running task to process balance change events'
  task balance: :environment do
    channel = Processing.channel

    queue = channel.queue('events', durable: true)
    channel.prefetch(1)

    begin
      queue.subscribe(manual_ack: true, block: true) do |delivery_info, _properties, body|
        puts "Got event: #{ body }"
        event = nil
        begin
          event = JSON.parse(body, symbolize_names: true)
        rescue JSON::ParserError => _
          channel.ack(delivery_info.delivery_tag)
          next
        end

        puts "  parsed: #{ event.inspect }"

        new_transaction_params = {
          currency: event[:currency],
          target: event[:target],
          source: event[:source],
          amount: event[:amount],
          status: 'confirmed'
        }

        trans = Transaction.find_by('transaction_id LIKE ?', event[:transaction_id])
        if trans.blank?
          Transaction.create new_transaction_params.merge(transaction_id: event[:transaction_id])
        else
          trans.update_attribute :status, 'confirmed'
        end

        channel.ack(delivery_info.delivery_tag)
      end
    rescue Interrupt => _
      Processing.close
    end
  end

end
