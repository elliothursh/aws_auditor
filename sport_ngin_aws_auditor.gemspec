# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sport_ngin_aws_auditor/version'

Gem::Specification.new do |spec|
  spec.name          = "sport_ngin_aws_auditor"
  spec.version       = SportNginAwsAuditor::VERSION
  spec.authors       = ["Elliot Hursh", "Emma Sax", "Brian Bergstrom"]
  spec.email         = ["elliothursh@gmail.com", "emma.sax4@gmail.com", "brian.bergstrom@sportngin.com"]
  spec.summary       = %q{AWS configuration as code}
  spec.description   = %q{Helps with AWS configuration}
  spec.homepage      = "https://github.com/sportngin/sport_ngin_aws_auditor"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'aws-sdk', '~>2'
  spec.add_dependency 'hashie', '~> 3.3'
  spec.add_dependency 'gli', '~> 2.10'
  spec.add_dependency 'highline', '~> 1.6'
  spec.add_dependency 'google_drive', '~> 1.0.0.pre2'
  spec.add_dependency 'google-api-client', '~> 0.8.6'
  spec.add_dependency 'rack', '>= 1.3.0'
  spec.add_dependency 'activesupport', '>= 3.2'
  spec.add_dependency 'httparty'
  spec.add_dependency 'colorize'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4.0"
end
