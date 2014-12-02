# Stacker

Stacker is a command-line utility to manage AWS CloudFormation stacks according
to the standards and conventions for our platform.


## Installation

This project creates a gemfile. It can be built and installed locally as follows:

    bundle install
    rake clean build
    gem install pkg/stacker-*.gem

Routine testing:

    rake spec

I've found I don't need to build or install the gem on my dev machine once I've done it
once - the "stack" command seems to use my local source.

## Usage

    stack help
