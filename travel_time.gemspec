# frozen_string_literal: true

require_relative 'lib/travel_time/version'

Gem::Specification.new do |spec|
  spec.name = 'travel_time'
  spec.version = TravelTime::VERSION
  spec.authors = ['TravelTime Team']
  spec.email = ['support@traveltime.com']

  spec.summary = 'TravelTime SDK for Ruby programming language'
  spec.description = 'TravelTime SDK for Ruby programming language'
  spec.homepage = 'https://traveltime.com'
  spec.license = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/traveltime-dev/traveltime-sdk-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/traveltime-dev/traveltime-sdk-ruby/releases'

  spec.add_dependency 'dry-configurable', '~> 0.14.0'
  spec.add_dependency 'faraday', '>= 1.10', '< 3.0'
  spec.add_dependency 'google-protobuf', '>= 3.21', '< 3.21.9'
  spec.add_dependency 'ruby-limiter', '~> 2.2.2'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir['{bin,lib}/**/*', 'LICENSE.md', 'Rakefile', 'README.md']
  spec.bindir = 'bin'
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
