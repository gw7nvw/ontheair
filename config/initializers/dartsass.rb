# config/initializers/dartsass.rb
Rails.application.configure do
  # Tell Dart Sass where to look for @import paths
  config.dartsass.build_options << " --load-path=node_modules"
end
