require 'fileutils'

module CCS
  class Configuration
    attr_reader :connections

    FILENAME = 'config.yml'.freeze

    def initialize(folder)
      @default = false
      @folder = folder
      create_default_config unless File.exist?(path)
      @config = YAML.load_file(path)
      @connections = {}
      @config['connections'].each do |connection|
        @connections[connection['sender_id']] = connection
      end
    end

    def connection(sender_id)
      return if sender_id.nil? || @connections[sender_id].nil?
      defaults.merge(@connections[sender_id])
    end

    def server_id
      @config['server_id'] || 1
    end

    def redis
      @config['redis'].merge(driver: :celluloid)
    end

    def defaults
      return @defaults if @defaults
      @defaults = @config['defaults'] || {}
      @defaults['time_to_live'] ||= 600
      @defaults['delay_while_idle'] ||= true
      @defaults['delivery_receipt_requested'] ||= false
      @defaults
    end

    def endpoint
      @config['endpoint'][@config['mode']]
    end

    def default?
      @default
    end

    def run?
      !!@config['run']
    end

    def path
      "#{@folder}/#{FILENAME}"
    end

    private

    def create_default_config
      FileUtils.mkdir_p(@folder) unless File.directory?(@folder)
      template = File.join(File.expand_path('../../..', __FILE__), 'config', 'ccs.yml')
      FileUtils.cp(template, path)
      @default = true
    end
  end
end
