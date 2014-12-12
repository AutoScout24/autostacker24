# Autostack24

Autostack24 is a small ruby library for managing AWS CloudFormation stacks for Autoscout24.

## Development setup

You should have ruby 2.0 or higher.

Run:

    gem install bundler
    bundle install

Add gem dependencies to the Gemfile, and re-run `bundle install`.


## Using

Declare a dependency on the autostack24 gem, preferably in a Gemfile:

    gem 'autostack24', :source => "file://#{Dir.home}/gem_repo"

Use it in your rakefile or Ruby code:

    require 'autostack24/service_stack'

See the lab-service for example code, or an existing Tatsu service.

