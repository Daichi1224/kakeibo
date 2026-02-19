#!/usr/bin/env bash
set -o errexit

echo "=== Step 1: bundle install ==="
bundle config set --local without 'development test'
bundle install --full-index

echo "=== Step 2: assets:precompile ==="
SECRET_KEY_BASE=dummy bundle exec rake assets:precompile

echo "=== Step 3: assets:clean ==="
bundle exec rake assets:clean

echo "=== Build complete ==="
