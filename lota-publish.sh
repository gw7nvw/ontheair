#!/bin/bash
cp config/database-lota.yml config/database.yml
cp db/seeds-lota.rb db/seeds.rb
RAILS_ENV=production bundle exec rake assets:clean assets:precompile
sudo cp -r /var/www/html/lota-ww/public/system /tmp/
sudo rm -r /var/www/html/lota-ww/*
sudo cp -r /home/mbriggs/rails_projects/hota/* /var/www/html/lota-ww/
sudo rm -r /var/www/html/lota-ww/public/system
sudo cp -r  /tmp/system /var/www/html/lota-ww/public/
sudo chmod a+rw /var/www/html/lota-ww/log/*
sudo chmod a+rwx /var/www/html/lota-ww/public/system
sudo chmod a+rwx /var/www/html/lota-ww/public/system/*
sudo chmod a+rwx /var/www/html/lota-ww/public/system/*/*
sudo chmod a+rw /var/www/html/lota-ww/public/system/*/*/*
sudo service apache2 restart
sudo /etc/rc.local
