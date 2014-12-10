#!/bin/sh

set -ueo pipefail
GEM_PATH="$(ruby -rubygems -e 'puts Gem.user_dir')/bin"
export PATH="${GEM_PATH}:${PATH:-}"

bundle install --path vendor/bundle
rake clean build
