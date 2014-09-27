# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_auditor/version'

Gem::Specification.new do |spec|
  spec.name          = "aws_auditor"
  spec.version       = AwsAuditor::VERSION
  spec.authors       = ["Elliot Hursh"]
  spec.email         = ["elliothursh@gmail.com"]
  spec.summary       = %q{AWS configuration as code}
  spec.description   = %q{Helps with AWS configuration}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'aws-sdk'
  spec.add_dependency 'hashie'
  spec.add_dependency 'gli', '~> 2.10'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
