require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ontheair
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0
    config.assets.prefix = "/rails-assets"
    #add modles from lib
    #config.autoload_paths += %W(#{config.root}/lib)
    #config.middleware.insert_after "ActionDispatch::Session::ActiveRecordStore", "DynamicCookieDomain"
    #config.middleware.insert_after "ActionDispatch::Session::ActiveRecordStore", "SkipBotSessions"
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Prevents pg_dump from outputting thousands of lines of PostGIS internal comments
    ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = ['--no-comments', '--no-owner']

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
     config.time_zone = "UTC"
    # config.eager_load_paths << Rails.root.join("extras")
    config.active_record.schema_format = :sql
  end
end
