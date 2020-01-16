require_relative 'lib/pmsx003/version'

Gem::Specification.new do |spec|
  spec.name          = 'pmsx003'
  spec.version       = Pmsx003::VERSION
  spec.authors       = ['sh7d']
  spec.email         = ['sh7d@sh7d']

  spec.summary       = %q(Ruby driver for PMSX003 air quality sensors)
  spec.description   = %q(Ruby driver and example cli for PMSX003 air quality sensors)
  spec.homepage      = 'https://github.com/sh7d/rpmsx003'
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/sh7d/rpmsx003'

  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.add_dependency 'rbuspirate', '>= 0.1.1'
  spec.add_dependency 'serialport', "~> 1.3"
  spec.add_dependency 'bindata', '~> 2.4'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'pry', '~> 0.12'
end
