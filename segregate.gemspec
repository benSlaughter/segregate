lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'segregate/version'

Gem::Specification.new do |spec|
  spec.name         = 'segregate'
  spec.summary      = 'Segregate http parser'
  spec.description  = 'An http parser that also includes URI parsing and retaining and rebuilding the original data'
  spec.homepage     = 'http://benslaughter.github.io/segregate/'
  spec.version      = Segregate::VERSION
  spec.date         = Segregate::DATE
  spec.license      = 'MIT'

  spec.author       = 'Ben Slaughter'
  spec.email        = 'b.p.slaughter@gmail.com'

  spec.files        = ['README.md', 'LICENSE']
  spec.files        += Dir.glob("lib/**/*.rb")
  spec.files        += Dir.glob("spec/**/*")
  spec.test_files   = Dir.glob("spec/**/*")
  spec.require_path = 'lib'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rspec'
end