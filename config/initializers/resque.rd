Resque.logger.formatter = Resque::QuietFormatter.new
Resque.schedule = YAML.load_file Rails.root.join('config', 'schedule.yml')

