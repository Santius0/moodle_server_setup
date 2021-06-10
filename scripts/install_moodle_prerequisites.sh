#!/bin/sh

add_ppa() {
  for i in "$@"; do
    grep -h "^deb.*$i" /etc/apt/sources.list.d/* > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
      echo "adding ppa:$i"
      sudo add-apt-repository ppa:"$i" -y
    else
      echo "ppa:$i already exists"
    fi
  done
}
remove_ppa() {
  for i in "$@"; do
    grep -h "^deb.*$i" /etc/apt/sources.list.d/* > /dev/null 2>&1
    if [ $? -ne 0 ]
    then
      echo "ppa:$i does not found"
    else
      echo "removing ppa:$i"
      sudo add-apt-repository --remove -y ppa:"$i"
    fi
  done
}

add_ppa ondrej/php
#remove_ppa ondrej/php

echo "installing moodle pre-requisites..."
sudo apt install apache2 mysql-client mysql-server php7.4 libapache2-mod-php -y

echo "installing apache2 plugins..."
sudo apt install graphviz aspell ghostscript clamav php7.4-pspell php7.4-curl php7.4-gd php7.4-intl php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-ldap php7.4-zip php7.4-soap php7.4-mbstring -y

echo "restarting apache2 service..."
sudo service apache2 restart

echo "installing git..."
sudo apt install git -y

cat << _EOF_
  Ensure your mysql basic configurations have been made, including setting your mysql root password.
  If you have already done this feel free to skip step 01, as it have you configure your basic mysql settings again.
_EOF_