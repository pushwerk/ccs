module CCS
  class UserNotification
    attr_accessor :operation, :registration_ids
    attr_accessor :notification_key_name, :notification_key

    OPERATIONS = %w(create add remove)

    def initialize(operation, registration_ids, notification_key_name = nil, notification_key = nil)
      @operation               = operation
      @registration_ids        = registration_ids
      @notification_key        = notification_key
      @notification_key_name   = notification_key_name
    end

    def valid?
      fail 'not a valid operation' unless OPERATIONS.include?(@operation)
      fail 'registration_ids must be an array' unless @registration_ids.is_a?(Array)
      fail 'registration_ids must contain at least 1 and at most 1000 ids' unless @registration_ids.size.between?(1, 1_000)
      fail 'notification_key cant be nil on add and remove' if @notification_key.nil? && %w(add remove).include?(@operation)
      fail 'notification_key_name cant be nil on create' if @notification_key_name.nil? && @operation == 'create'
    end

    def to_json
      valid?
      msg = {}
      msg['operation']                  = operation
      msg['notification_key_name']      = notification_key_name    unless notification_key_name.nil?
      msg['notification_key']           = notification_key         unless notification_key.nil? || operation == 'create'
      msg['registration_ids']           = registration_ids
      Oj.dump(msg)
    end
  end
end
