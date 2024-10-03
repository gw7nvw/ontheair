# frozen_string_literal: true

require 'resque/tasks'
require 'resque/scheduler/tasks'
task 'resque:preload' => :environment
namespace :resque do
  task :setup do
    require 'resque'
    Resque.redis = 'localhost:6379'
  end
  task setup_schedule: :setup do
    require 'resque-scheduler'
    require 'resque/scheduler/server'
    Resque.schedule = YAML.load_file('config/resque_schedule.yml')
    require 'get_spots'
  end
  task scheduler: :setup_schedule
  task setup: :environment do
    require '/home/mbriggs/rails_projects/hota-2.2/lib/resque_process_email.rb'
  end
end
