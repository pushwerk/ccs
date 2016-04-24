module CCS
  class Notification
    using FixnumExtensions

    attr_reader :id

    def initialize(sender_id, to, data = {}, option_params = {})
      @sender_id = sender_id
      @to = to
      @data = data
      @data = { data: @data } if @data && @data.class != Hash
      self.options = option_params
      @id = SecureRandom.uuid
    end

    def to_json
      msg = {
        'to' => @to,
        'data' => @data,
        'message_id' => @id
      }
      msg.merge!(options)
      msg.delete_if { |_k, v| v.nil? || v.empty? }.to_json
    end

    def options=(params)
      return @options if @options
      @options = CCS.config
                    .connection(sender_id)
                    .merge(params)
                    .delete_if { |key| ![:collapse_key, :time_to_live, :delay_while_idle, :delivery_receipt_requested].include?(key) }
      @options[:time_to_live] = @options[:time_to_live].at_least(0).at_most(2_419_200) if @options[:time_to_live]
      @options[:delay_while_idle] = !!@options[:delay_while_idle]
      @options[:delivery_receipt_requested] = !!@options[:delivery_receipt_requested]
      @options
    end
  end
end
