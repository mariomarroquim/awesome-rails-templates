# frozen_string_literal: true

gem_group :development, :test do
  # Improve code debugging.
  gem 'awesome_print'

  # Minimize database issues.
  gem 'bullet'
end

gem_group :development do
  # Improve code debugging.
  gem 'better_errors'
  gem 'binding_of_caller'

  # Secure code and libraries.
  gem 'bundler-audit'

  # Minimize database issues.
  gem 'database_consistency', require: false

  # Minimize performance issues.
  gem 'rubocop-performance', require: false
end

after_bundle do
  run 'yes y | bundle exec rails g bullet:install'

  run 'bundle exec database_consistency install'
end

inject_into_file '.rubocop.yml' do
  "\n# Minimize performance issues.\nplugins: rubocop-performance\n"
end

file 'run_pre_commit_checks.sh', <<~CONTENT
  #!/bin/bash

  # Script for running various pre-commit checks for a Ruby on Rails project.

  printf  "\\n== RUNNING BUNDLER-AUDIT ==\\n\\n"
  bundle exec bundle-audit --update
  sleep 3

  printf  "\\n== RUNNING BRAKEMAN ==\\n"
  bundle exec brakeman -A -q --summary
  sleep 3

  printf  "== RUNNING DATABASE-CONSISTENCY ==\\n\\n"
  bundle exec database_consistency -f
  sleep 3

  printf  "\\n== RUNNING RUBOCOP ==\\n\\n"
  bundle exec rubocop -a
  sleep 3

  printf  "\\n== RUNNING TESTS ==\\n\\n"
  bundle exec rails test
  sleep 3

  printf  "\\n== RUNNING CLEANING ==\\n\\n"
  bundle exec rails assets:clobber tmp:clear log:clear
  printf "Done cleaning\\n"

  printf  "\\n== ALL CHECKS DONE! ==\\n\\n"
CONTENT
