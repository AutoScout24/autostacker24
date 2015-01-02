Gem::Specification.new do |s|
    s.name           = 'autostacker24'
    s.authors        = ['Johannes Mueller', 'Christian Rodemeyer']
    s.email          = %w(jmueller@autoscout24.com crodemeyer@autoscout24.com)
    s.homepage       = 'https://github.com/AutoScout24/autostacker24'
    s.summary        = 'Library for managing AWS CloudFormation stacks'
    s.description    = 'n/a'
    s.license        = 'MIT'
    s.files          = FileList['lib/**/*']
    s.version        = "1.0.1"
    s.add_dependency 'aws-sdk', '~> 2.0.pre'
end