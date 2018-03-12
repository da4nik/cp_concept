module Processing
  RPC_QUEUE = 'processing'.freeze

  class << self
    def channel
      @channel ||= connection.create_channel
    end

    def connection
      @connection ||= Bunny.new.tap(&:start)
    end

    def new_transaction
      @new_transaction ||= Processing::NewTransaction.new
    end

    def close
      channel.close
      connection.close
    end
  end
end
