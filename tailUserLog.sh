tail -f /var/www/html/hota/log/production.log | grep --line-buffered -b3 USER | grep -e "USER" -e "Started"

