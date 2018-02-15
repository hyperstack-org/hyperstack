#!/bin/bash
export HYPER_DEV_GEM_SOURCE='https://gems.ruby-hyperloop.org'
export RAILS_ENV="test"
bundle update
cd spec/test_app
bundle update
cd ../..
