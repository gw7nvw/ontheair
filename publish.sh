#!/bin/bash
set -e # Exit immediately if any command fails

APP_PATH="/var/www/ontheair"
echo "Starting Ontheair Deployment..."

# 1. Pull the fresh repository code structure from Git
cd $APP_PATH
git fetch origin
#git checkout master
git checkout rails-8-upgrade
#git pull origin master
git pull origin rails-8-upgrade

# 2. Install Ruby gems cleanly without development tests
bundle config set --local deployment 'true'
bundle config set --local without 'development test'
bundle install

# 3. Install JavaScript Node packages
npm ci --omit=dev  # Fast, clean, locked package installer
npm install esbuild # Ensure the compiler binary exists on production disk

# 4. Run database migrations safely using your restricted Postgres user
RAILS_ENV=production bundle exec rails db:migrate

# 5. PRECOMPILE PRODUCTION ASSETS (CRITICAL FOR RAILS 8)
# This triggers 'npm run build' and 'dartsass:build' automatically,
# then drops the optimized, minified files directly into public/assets/
RAILS_ENV=production bundle exec rails assets:precompile

# 6. RELOAD PHUSION PASSENGER INSTANTLY WITHOUT DOWNTIME
sudo service apache2 restart

echo "Deployment completed successfully!"

