require 'resque/tasks'
require 'resque/scheduler/tasks'
task "resque:preload" => :environment
namespace :resque do
  task :setup do
    require 'resque'
  end
  task :setup_schedule => :setup do
    require 'resque-scheduler'
  end
  task :scheduler => :setup_schedule
  task :setup => :environment do
    require "/home/mbriggs/rails_projects/hota/lib/resque_process_email.rb"
  end
end


