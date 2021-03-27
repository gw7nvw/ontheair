#!/bin/bash
RAILS_ENV=production bundle exec rake assets:clean assets:precompile
sudo rm -r /var/www/html/hota/*
sudo cp -r /home/mbriggs/rails_projects/hota/* /var/www/html/hota/
sudo chmod a+rw /var/www/html/hota/log/*
sudo service apache2 restart
sudo /etc/rc.local
