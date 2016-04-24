module CCS
  class HandlerSupervisor
    def initialize
      @supervisor = Celluloid::Supervision::Container.new
      CCS.config.connections.each do |sender_id, _settings|
        start_handler(sender_id)
      end
      @supervisor.class.run!
    end

    def start_handler(sender_id)
      @supervisor.add(type: ConnectionHandler, as: "handler_#{sender_id}", args: [sender_id])
    end
  end
end
