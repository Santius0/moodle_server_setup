#!/bin/sh

db_root_user="root"
YES_ALL=false

while [ "$1" != "" ]; do
    # shellcheck disable=SC2006
    PARAM=`echo "$1" | awk -F= '{print $1}'`
    # shellcheck disable=SC2006
    # shellcheck disable=SC2034
    VALUE=`echo "$1" | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -y | -Y)
            YES_ALL=true
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done


# shellcheck disable=SC2039
read -r -p "Enter the name of the Moodle database (default='moodle'): " db_moodle
if [ -z "$db_moodle" ]; then
  db_moodle="moodle"
fi
# shellcheck disable=SC2039
read -r -p "Enter the name of the Moodle database host (default='localhost'): " db_moodle_host
if [ -z "$db_moodle_host" ]; then
  db_moodle_host="localhost"
fi
echo "The database '${db_moodle}'@'${db_moodle_host}' will be completely wiped and recreated."
if [ $YES_ALL = true ]; then
    continue="Y"
else
  while true; do
    # shellcheck disable=SC2039
    read -r -p "Are you sure you want to continue? Y/N: " continue
    case $continue in
      [Yy]* )
        break
        ;;
      [Nn]* )
        echo "exiting..."
        exit
        ;;
      *)
        echo "Please select either Yes(Y) or No(N)"
        ;;
    esac
  done
fi

echo "Please provide the requested credentials to continue"
# shellcheck disable=SC2039
read -r -s -p "MySql root password: " db_root_password
echo ""
# shellcheck disable=SC2039
read -r -p "Username of '${db_moodle}' user (default='moodle_user'): " db_moodle_user
if [ -z "$db_moodle_user" ]; then
  db_moodle_user="moodle_user"
fi
# shellcheck disable=SC2039
read -r -s -p "Password for user '${db_moodle_user}': " db_moodle_user_password
mysql --user="${db_root_user}" --password="${db_root_password}" <<_EOF_
  DROP DATABASE IF EXISTS ${db_moodle};
  DROP User IF EXISTS '${db_moodle_user}'@'${db_moodle_host}';
  CREATE DATABASE ${db_moodle} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE User '${db_moodle_user}'@'${db_moodle_host}' IDENTIFIED BY '${db_moodle_user_password}';
  GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON ${db_moodle}.* TO '${db_moodle_user}'@'${db_moodle_host}';
_EOF_