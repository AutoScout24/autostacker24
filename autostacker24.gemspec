require 'rubygems'
include FileUtils

MINOR_VERSION = ENV['GO_PIPELINE_LABEL'] || "pre#{Time.now.tv_sec}"

Gem::Specification.new do |s|
  s.name           = 'autostacker24'
  s.authors        = ['Johannes Mueller', 'Christian Rodemeyer']
  s.email          = %w(jmueller@autoscout24.com crodemeyer@autoscout24.com)
  s.homepage       = 'https://github.com/AutoScout24/autostacker24'
  s.summary        = 'Library for managing AWS CloudFormation stacks'
  s.description    = 'n/a'
  s.license        = 'MIT'
  s.files         = `git ls-files lib -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.version        = "1.0.#{MINOR_VERSION}"
  s.executables    = ["autostacker24"]
  s.add_dependency 'aws-sdk-core', '~> 2'
  s.add_dependency 'json', '~> 1.8'
  s.add_dependency 'json_pure', '~> 1.8'
  s.add_development_dependency 'rubocop', '~> 0.37'
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency 'rspec', '~> 3.4'

end
