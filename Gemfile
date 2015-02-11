source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.0'

# Use sequel instead of Active Record
gem 'pg'
gem 'sequel-rails'

# Resources
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'slim'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails' #, '3.1.2' # Not working with 4.0
#gem 'jquery-ui-rails'

gem 'foundation-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

gem 'devise'
gem 'sequel-devise'

gem 'ember-rails'
gem 'ember-source' #, '~> 1.8.1' # Fix to work on 1.9

gem 'emblem-rails'

gem 'barber-emblem', git:'https://github.com/simcha/barber-emblem.git'
gem 'emblem-source', git:'https://github.com/machty/emblem.js.git'

gem 'user_agent_parser'
gem 'high_voltage'

# Testing
group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  #gem 'spring'

  #gem 'sass-rails-source-maps'
  #gem 'coffee-rails-source-maps'

  #gem 'konacha'
  #gem 'selenium-webdriver'

  gem 'rspec-rails', '~> 3.0.0'
  gem 'factory_girl_rails'
  gem 'faker'
end

group :test do
  gem 'simplecov'
#  gem 'capybara'
#  gem 'guard-rspec'
#  gem 'launchy'
end

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
gem 'spring',        group: :development

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

gem 'tzinfo-data', platforms: [:mingw, :mswin]

# For fetch
group :development do
  gem 'typhoeus'
  gem 'nokogiri'
end