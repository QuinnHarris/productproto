# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( templates/all.js pages.css pages.js )

# Make Teaspoon in development and testing happy
unless Rails.env.production?
  Rails.application.config.assets.precompile += %w( teaspoon.css teaspoon-teaspoon.js teaspoon-mocha.js mocha/1.17.1.js )
end