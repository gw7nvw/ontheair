#!/bin/bash
RAILS_ENV=production bundle exec rake assets:clean assets:precompile
sudo cp -r /var/www/html/hota/public/system /tmp/
sudo rm -r /var/www/html/hota/*
sudo cp -r /home/mbriggs/rails_projects/hota/* /var/www/html/hota/
sudo rm -r /var/www/html/hota/public/system
sudo cp -r  /tmp/system /var/www/html/hota/public/
sudo chmod a+rw /var/www/html/hota/log/*
sudo chmod a+rwx /var/www/html/hota/public/system
sudo chmod a+rwx /var/www/html/hota/public/system/*
sudo chmod a+rwx /var/www/html/hota/public/system/*/*
sudo chmod a+rw /var/www/html/hota/public/system/*/*/*
sudo service apache2 restart
sudo /etc/rc.local
