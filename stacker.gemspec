# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name           = 'stacker'

  minor_ver = `git log -n 1 --pretty=format:'%at' #{File.dirname(__FILE__)} 2> /dev/null`
  spec.version        = "1.0.#{minor_ver}"

  spec.authors        = ['tatsu']
  spec.email          = ['tatsu@autoscout24.com']
  spec.description    = 'Library for managing AWS CloudFormation stacks'
  spec.summary        = 'Library for managing AWS CloudFormation stacks'
  spec.license        = 'MIT'

  spec.files          = Dir['{bin,lib}/**/*']
  spec.executables    = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files     = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths  = ['lib']

  spec.add_dependency 'aws-sdk', '~> 2.0.pre'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
