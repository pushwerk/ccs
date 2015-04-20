# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ccs/version'

Gem::Specification.new do |spec|
  spec.name          = 'ccs'
  spec.version       = CCS::VERSION
  spec.authors       = ['l3akage']
  spec.email         = ['info@l3akage.de']
  spec.summary       = 'Implementation of Google CCS-API'
  spec.description   = 'Implementation of Google CCS-API'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'celluloid-redis'
  spec.add_dependency 'hiredis'
  spec.add_dependency 'redis'
  spec.add_dependency 'ox'
  spec.add_dependency 'oj'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
