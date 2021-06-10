#!/bin/sh

if [ "$#" -ne "1" ]; then
  echo "Expected 1 arguments got $#" >&2
  usage
  exit 2
fi

website_on_this_server=${1}

echo "adding and enabling moodle.conf"
sudo cp ./moodle.conf /etc/apache2/sites-available/moodle.conf
sudo a2dissite moodle.conf
sudo a2ensite moodle.conf

if $website_on_this_server ; then
  echo "adding and enabling website.conf"
  sudo cp ./website.conf /etc/apache2/sites-available/website.conf
  sudo a2dissite website.conf
  sudo a2ensite website.conf
fi

sudo a2dissite 000-default.conf
sudo systemctl reload apache2
#sudo service apache2 restart