require 'oj'
require 'json'
require 'ox'
require 'redis'
require 'xmpp_simple'
require 'celluloid'
require 'celluloid/redis'

require 'ccs/version'
require 'ccs/redis_helper'
require 'ccs/configuration'
require 'ccs/notification'
require 'ccs/user_notification'
require 'ccs/semaphore'
require 'ccs/callback_handler'
require 'ccs/xmpp_connection_handler'
require 'ccs/xmpp_connection'
require 'ccs/http_worker'

module CCS
  attr_reader :callback

  XMPP_ERROR_QUEUE   = 'ccs_xmpp_error'
  XMPP_QUEUE         = 'ccs_xmpp_sending'
  UPSTREAM_QUEUE     = 'ccs_upstream'
  RECEIPT_QUEUE      = 'ccs_receipt'

  CONNECTIONS        = 'ccs_connections'
  MAX_MESSAGES       = 100
  @callback          = {}

  module_function

  ## Main functions
  def start
    configuration.valid?
    XMPPConnectionHandler.new(CCS.configuration.connection_count)
    CallbackHandler.new
  end

  ## Configuration
  def configuration
    @configuration ||= Configuration.new
  end

  def configure
    yield(configuration) if block_given?
  end

  def reset_configuration
    @configuration = Configuration.new
  end

  ## Logging
  attr_writer :logger

  def logger
    @logger ||= Logger.new($stdout).tap do |logger|
      logger.level = Logger::ERROR
      logger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity} :: #{datetime.strftime('%d-%m-%Y :: %H:%M:%S')} :: #{progname} :: #{msg}\n"
      end
    end
  end

  def debug(message)
    logger.debug(message.inspect)
  end

  def info(message)
    logger.info(message.inspect)
  end

  def error(message)
    logger.error(message.inspect)
  end

  def mutex
    @mutex ||= Mutex.new.tap { @last_id = 0 }
  end

  def next_id
    mutex.synchronize do
      @last_id += 1
      return format('%010x', @last_id)
    end
  end

  ## CCS Api
  def send(to, data = {}, options = {})
    msg = Notification.new(to, data, options)
    id = next_id
    msg.message_id = id
    RedisHelper.lpush(XMPP_QUEUE, msg.to_json)
    id
  end

  ## GCM Api
  def create(registration_ids, notification_key_name)
    fail 'name cannot be nil' if notification_key_name.nil?
    fail 'registration_ids must be an array' unless registration_ids.is_a? Array
    notification_key('create', registration_ids, notification_key_name)
  end

  def add(registration_ids, notification_key, notification_key_name = nil)
    fail 'key cannot be nil' if notification_key.nil?
    fail 'registration_ids must be an array' unless registration_ids.is_a? Array
    notification_key('add', registration_ids, notification_key_name, notification_key)
  end

  def remove(registration_ids, notification_key, notification_key_name = nil)
    fail 'key cannot be nil' if notification_key.nil?
    fail 'registration_ids must be an array' unless registration_ids.is_a? Array
    notification_key('remove', registration_ids, notification_key_name, notification_key)
  end

  def notification_key(operation, registration_ids, notification_key_name = nil, notification_key = nil)
    msg = UserNotification.new(operation, registration_ids, notification_key_name, notification_key)
    HTTPWorker.new.query msg
  end

  ## Access
  def on_receipt(&block)
    @callback[:receipt] = block
  end

  def on_error(&block)
    @callback[:error] = block
  end

  def on_upstream(&block)
    @callback[:upstream] = block
  end
end
