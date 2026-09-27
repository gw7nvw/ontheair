# config/initializers/resque.rb
require 'resque'
require 'resque-scheduler'

# 1. Connect to your production/UAT Redis socket pool
Resque.redis = ENV.fetch('REDIS_URL', 'localhost:6379')

# 2. THE SEPARATE LOGGER FIX: Create a dedicated log file inside log/resque.log
# We use ActiveSupport::Logger so it retains standard Rails log-formatting helpers
resque_log_path = Rails.root.join('log', "resque.log")

resque_logger = ActiveSupport::Logger.new(resque_log_path)
resque_logger.level = Rails.logger.level
Resque.logger = resque_logger

scheduler_log_path = Rails.root.join('log', "scheduler.log")
scheduler_logger = ActiveSupport::Logger.new(scheduler_log_path)
scheduler_logger.level = Rails.logger.level
Resque::Scheduler.logger = scheduler_logger if defined?(Resque::Scheduler)

# 3. Load your static cron schedule configuration file if it exists
schedule_file = Rails.root.join('config', 'resque_schedule.yml')
if File.exist?(schedule_file)
  Resque.schedule = YAML.load_file(schedule_file)
end
