module CCS
  class Notification
    attr_accessor :collapse_key, :message_id
    attr_reader :to, :data, :type

    def initialize(to, data = {}, options = {})
      fail 'recipient must be set' if to.nil?
      fail 'registration_ids must contain at least 1 and at most 1000 ids' if to.is_a?(Array) unless to.size.between?(1, 1_000)
      @type = to.is_a?(Array) ? :http : :xmpp
      @to                              = to
      self.data                        = data
      self.time_to_live                = options[:time_to_live]
      self.delay_while_idle            = options[:delay_while_idle]
      self.delivery_receipt_requested  = options[:delivery_receipt_requested]
    end

    def data=(value)
      fail "invalid data type: #{value.class}" if value.class != Hash
      @data = value
    end

    def time_to_live
      @time_to_live || CCS.configuration.default_time_to_live
    end

    def time_to_live=(value)
      return if value.nil?
      fail 'must be a fixnum' unless value.class == Fixnum
      fail 'must be between 0 and 2419200 seconds' unless value.between?(0, 2_419_200)
      @time_to_live = value
    end

    def delay_while_idle
      @delay_while_idle || CCS.configuration.default_delay_while_idle
    end

    def delay_while_idle=(value)
      @delay_while_idle = value ? true : false
    end

    def delivery_receipt_requested
      @delay_while_idle || CCS.configuration.default_delay_while_idle
    end

    def delivery_receipt_requested=(value)
      return if type == :http
      @delay_while_idle = value ? true : false
    end

    def to_json
      msg = {}
      if type == :xmpp
        msg['to']                         = to
      else
        msg['registration_ids']           = to
      end
      msg['data']                         = data                        unless data.nil?
      msg['message_id']                   = message_id                  unless message_id.nil?
      msg['collapse_key']                 = collapse_key                unless collapse_key.nil?
      msg['time_to_live']                 = time_to_live                unless time_to_live.nil?
      msg['delay_while_idle']             = delay_while_idle            unless delay_while_idle.nil?
      msg['delivery_receipt_requested']   = delivery_receipt_requested  unless delivery_receipt_requested.nil? || type == :http
      msg.to_json
    end
  end
end
