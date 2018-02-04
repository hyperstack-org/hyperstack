#!/bin/bash
export HYPER_DEV_GEM_SOURCE="https://gems.ruby-hyperloop.org"
export RAILS_ENV="test"
pwd
echo
echo "Running with Chrome headless"
DRIVER=headless bundle exec rspec
# echo
# echo "Running with Firefox headless"
# DRIVER=beheaded bundle exec rspec
