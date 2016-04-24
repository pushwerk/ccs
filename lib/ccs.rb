require 'json'
require 'yaml'
require 'redis'
require 'xmpp_simple'
require 'celluloid/current'
require 'celluloid/redis'
require 'securerandom'

require 'ccs/version'
require 'ccs/semaphore'
require 'ccs/configuration'

require 'ccs/extensions/redis_extensions'
require 'ccs/extensions/fixnum_extensions'

require 'ccs/xmpp/notification'
require 'ccs/xmpp/xmpp_connection'
require 'ccs/xmpp/connection_handler'

require 'ccs/handler_supervisor'

module CCS
  MAX_MESSAGES = 100
  MAX_CONNECTIONS = 1_000

  module_function

  ## Main functions to start CCS
  def start
    if config.default?
      puts "Example config has been placed in #{config.path}"
      return
    end
    unless config.run?
      puts "You have to configure the ccs first, check: #{config.path}"
      return
    end
    XMPPSimple.logger = logger
    HandlerSupervisor.new
  end

  ## Configuration
  def config
    @config ||= Configuration.new(File.join(ENV['HOME'], '.config', 'ccs'))
  end

  ## Logging
  def logger=(value)
    @logger = value
  end

  def logger
    return @logger if @logger
    @logger = Logger.new($stdout).tap do |log|
      log.level = Logger::DEBUG
    end
  end

  def queues(sender_id)
    prefix = "ccs_#{CCS.config.server_id}_#{sender_id}"
    {
      ccs_error: "#{prefix}_ccs_error",
      ccs_queue: "#{prefix}_ccs_queue",
      upstream_queue: "#{prefix}_upstream_queue",
      receipt_queue: "#{prefix}_receipt_queue"
    }
  end
end
