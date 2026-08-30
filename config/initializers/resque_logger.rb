# config/initializers/resque_logger.rb

# 1. Instantiate the isolated log file target
resque_log_path = Rails.root.join('log', 'resque.log')
resque_logger = ActiveSupport::Logger.new(resque_log_path)

# 2. Force it to capture verbose debug messages independently of your web server settings
resque_logger.level = Logger::DEBUG

# 3. Add timestamp formatting to ensure background tasks are easily auditable
resque_logger.formatter = Logger::Formatter.new

# 4. Bind this logger directly to the global Resque engine configuration
Resque.logger = resque_logger

