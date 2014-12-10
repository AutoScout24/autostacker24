#!/bin/sh

set -ueo pipefail
bundle install --path vendor/bundle
rake clean build
