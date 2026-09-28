# lib/tasks/resque.rake
require 'resque/tasks'
require 'resque/scheduler/tasks'

namespace :resque do
  task setup: :environment do
    # This hook forces your worker sub-processes to load the full Rails 
    # environment, giving your jobs full access to ActiveRecord and PostGIS models!
    ENV['QUEUE'] ||= '*'
  end

  task scheduler: :setup
end
