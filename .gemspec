    # This file is only necessary to help Bundler installing directly the newest version from Github directly

    Gem::Specification.new do |s|
      s.name           = 'autostacker24'
      s.summary        = 'Library for managing AWS CloudFormation stacks'
      s.version        = "1.0.1420193788"
      s.add_dependency 'aws-sdk', '~> 2.0.pre'
    end
