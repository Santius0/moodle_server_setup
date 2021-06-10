#!/bin/sh

# sudo ./setup_cron /var/www/moodle

if [ "$#" -ne "1" ]; then
  echo "Expected 1 arguments got $#" >&2
  usage
  exit 2
fi

moodle_root=${1}

if [ -e "${moodle_root}/admin/cli/cron.php" ]; then
  #  php_location=${which php}
  php_location="/usr/bin/php"
  ${php_location} "${moodle_root}"/admin/cli/cron.php
else
  echo "${moodle_root}/admin/cli/cron.php not found"
  exit 0
fi

cat << _EOF_
    Add the following line to the crontab:
      * * * * * ${php_location} ${moodle_root}/admin/cli/cron.php >> /var/log/moodle_cron/moodle_cron.log 2>&1
    Access the crontab using the command:
      crontab -u www-data -e
_EOF_
