#!/bin/bash
cp config/database-zlota.yml config/database.yml
cp db/seeds-zlota.rb db/seeds.rb
RAILS_ENV=production bundle exec rake assets:clean assets:precompile
sudo cp -r /var/www/html/hota-dev/public/system /tmp/
sudo cp -r /var/www/html/hota-dev/public/assets/assets.* /tmp/
sudo cp -r /var/www/html/hota-dev/public/assets/sites.* /tmp/
sudo rm -r /var/www/html/hota-dev/*
sudo cp -r /home/mbriggs/rails_projects/hota-2.2/* /var/www/html/hota-dev/
sudo rm -r /var/www/html/hota-dev/public/system
sudo cp -r  /tmp/system /var/www/html/hota-dev/public/
sudo cp -r  /tmp/assets.* /var/www/html/hota-dev/public/assets
sudo cp  dev-env-production.rb /var/www/html/hota-dev/config/environments/production.rb
sudo cp  dev-initialzers.rb /var/www/html/hota-dev/config/initializers/dev-initialzers.rb
sudo chmod -R a+rw /var/www/html/hota-dev/log/*
sudo chmod -R a+rw /var/www/html/hota-dev/public/system
sudo chmod -R a+rw /var/www/html/hota-dev/public/assets
sudo chgrp -R webadmin /var/www/html/hota-dev/log
sudo service apache2 restart
sudo /etc/rc.local
