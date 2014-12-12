# Stacker

Stacker is a small ruby library for managing AWS CloudFormation stacks for Autoscout24.

## Development setup

You should have ruby 2.0 or higher.

Run:

    gem install bundler
    bundle install

Add gem dependencies to the Gemfile, and re-run `bundle install`.


## Using

Declare a dependency on the stacker gem (note: work in progress), preferably in a Gemfile:

    gem 'stacker', :source => 'https://TBD'

Use it in your rakefile or Ruby code:

    require 'stacker/service_stack'

See the lab-service for example code, or an existing Tatsu service.

