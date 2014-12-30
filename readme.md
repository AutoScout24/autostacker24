# AutoStacker24

AutoStacker24 is a small ruby library for managing AWS CloudFormation stacks.

## Development setup

You should have ruby 2.0 or higher.

Run:

    gem install bundler
    bundle install

Add gem dependencies to the Gemfile, and re-run `bundle install`.


## Using

Declare a dependency on the gem, preferably in a Gemfile:

    gem 'autostacker24', :source => 'https://as24.tatsu.artefacts.s3.amazonaws.com/gem_repo/'

Use it in your rakefile or Ruby code:

    require 'autostacker24'

See the lab-service for example code, or an existing Tatsu service.

