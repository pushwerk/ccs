# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ccs/version'

Gem::Specification.new do |spec|
  spec.name          = 'ccs'
  spec.version       = CCS::VERSION
  spec.authors       = ['l3akage']
  spec.email         = ['info@l3akage.de']

  spec.homepage      = 'https://github.com/pushwerk/ccs'
  spec.summary       = 'Implementation of Google CCS-API'
  spec.description   = 'Google XMPP GCM Server as ruby gem using Celluloid and Redis'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting "allowed_push_host", or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'TODO: Set to "http://mygemserver.com"'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = %w( ccs_server )
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'celluloid', '~> 0.17.3'
  spec.add_dependency 'celluloid-redis', '~> 0.0.2'
  spec.add_dependency 'redis', '~> 3.3'
  spec.add_dependency 'nokogiri', '~> 1.6'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 11.1'
end
