require 'rubygems'
include FileUtils

Gem::Specification.new do |s|
  s.name           = 'autostacker24'
  s.authors        = ['Johannes Mueller', 'Christian Rodemeyer']
  s.email          = %w(jmueller@autoscout24.com crodemeyer@autoscout24.com)
  s.homepage       = 'https://github.com/AutoScout24/autostacker24'
  s.summary        = 'Library for managing AWS CloudFormation stacks'
  s.description    = 'AutoStacker24 is a small ruby gem for managing AWS CloudFormation stacks. It is a thin wrapper around the AWS Ruby SDK. It lets you write simple and convenient automation scripts, especially if you have lots of parameters or dependencies between stacks. You can use it directly from Ruby code or from the command line. It enhances CloudFormation templates by parameter expansion in strings and it is even possible to write templates in YAML which is much friendlier to humans than JSON. You can use autostacker24 cli to convert existing templates to YAML.'
  s.license        = 'MIT'
  s.files          = `git ls-files lib -z`.split("\x0") << 'license.txt'
  s.version        = "2.7.0"
  s.executables    = ['autostacker24']

  s.add_dependency 'aws-sdk-core', '~> 2'
  s.add_dependency 'json', '~> 2.0'
  s.add_dependency 'json_pure', '~> 2.0'

  s.add_development_dependency 'rubocop', '~> 0.37'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 3.4'

  puts s.files

end
