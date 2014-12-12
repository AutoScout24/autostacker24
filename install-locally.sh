#!/bin/sh

set -ueo pipefail

bundle install --path vendor/bundle
rake clean build
mkdir -p ~/gem_repo/gems
cp pkg/stacker-*.gem ~/gem_repo/gems/
pushd ~/gem_repo
gem generate_index
popd

