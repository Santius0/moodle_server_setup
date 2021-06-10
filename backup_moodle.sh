#!/bin/bash

BACKUPS_BASE_DIR="/opt/moodle_backups"
if [ ! -d "${BACKUPS_BASE_DIR}" ]; then
  mkdir "${BACKUPS_BASE_DIR}"
fi

MOODLE_ROOT="/var/www/html/moodle"
MOODLE_DATA="/var/www/moodledata"
MOODLE_DATABASE_NAME="moodle"
MOODLE_DATABASE_HOST="localhost"

POST_DELETE=false
YES_ALL=false
FORCE=false

usage() {
  #    echo "sample usage: ${0} -c --moodle-core=/opt/moodle --moodle-root=/var/www/html/moodle --moodle-data=/var/www/moodledata --moodle-repo=git://git.moodle.org/moodle.git --moodle-branch=MOODLE_39_STABLE -y"
  echo "sample usage: ${0}  -y"
  echo ""
  printf "\t -h --help\n\n"
  printf "\t -p --post-delete=%s\n" "${POST_DELETE}"
  echo ""
}

delete_dir() {
  for i in "$@"; do
    echo "Deleting $i ..."
    sudo rm -rf "$i"
  done
}

copy_dir() {
  src=${1}
  dest=${2}
  if [ ! -d "${src}" ]; then
    echo -e "\e[1;31m Directory '${src}' does not exist \e[0m"
    echo -e "\e[1;31m exiting...\e[0m"
    exit 2
  fi
  if [ -d "${dest}" ]; then
    if [ "${FORCE}" = true ]; then
      delete_dir "${dest}"
    else
      echo -e "\e[1;31m ERROR: Directory ${dest} already exists. Either delete ${dest} or use -f --force \e[0m"
      echo -e "\e[1;31m exiting... \e[0m"
      exit 2
    fi
  fi
  sudo cp -R "${src}" "${dest}"
}

while [ "$1" != "" ]; do
  PARAM=$(echo "$1" | awk -F= '{print $1}')
  VALUE=$(echo "$1" | awk -F= '{print $2}')
  case $PARAM in
  -h | --help)
    usage
    exit
    ;;
   -mr | --moodle-root)
    MOODLE_ROOT=$VALUE
    ;;
  -md | --moodle-data)
    MOODLE_DATA=$VALUE
    ;;
  -mdb | --moodle-database)
    MOODLE_DATABASE_NAME=$VALUE
    ;;
  -mdbh | --moodle-database-host)
    MOODLE_DATABASE_HOST=$VALUE
    ;;
  -b | --backup-dir)
    BACKUP_DIR=$VALUE
    ;;
  -p | --post-delete)
    POST_DELETE=true
    ;;
  -dbu | --database-username)
    DATABASE_USERNAME=$VALUE
    ;;
  -dbp | --database-password)
    DATABASE_PASSWORD=$VALUE
    ;;
  -y | -Y)
    YES_ALL=true
    ;;
  -f | --force)
    FORCE=true
    ;;
  *)
    echo -e "\e[1;31m ERROR: unknown parameter \"$PARAM\" \e[0m"
    usage
    exit 1
    ;;
  esac
  shift
done

if [ "${YES_ALL}" = true ]; then
  YES_FLAG="-y"
else
  YES_FLAG=""
fi

sudo apt-get install zip "${YES_FLAG}"

now=$(date +"%d-%m-%Y_%H:%M:%S")
if [ -z "${BACKUP_DIR}" ]; then
  BACKUP_DIR="/opt/moodle_backups/${now}"
fi

if [ -d "${BACKUP_DIR}" ]; then
  if [ "${FORCE}" = true ]; then
    delete_dir "${BACKUP_DIR}"
  else
    echo -e "\e[1;31m ERROR: Directory ${BACKUP_DIR} already exists. Either delete ${BACKUP_DIR} or use -f --force \e[0m"
    exit
  fi
fi

sudo mkdir "${BACKUP_DIR}"
copy_dir "${MOODLE_ROOT}" "${BACKUP_DIR}/moodle"
copy_dir "${MOODLE_DATA}" "${BACKUP_DIR}/moodledata"

while [ -z "${DATABASE_USERNAME}" ]; do
  read -rp "MySql Username: " DATABASE_USERNAME
done

while [ -z "${DATABASE_PASSWORD}" ]; do
  read -rsp "MySql Password: " DATABASE_PASSWORD
  echo ""
done

mysqldump --default-character-set=utf8mb4 -h "${MOODLE_DATABASE_HOST}" --user="${DATABASE_USERNAME}" --password="${DATABASE_PASSWORD}" -C -Q -e --create-options "${MOODLE_DATABASE_NAME}" > "${BACKUP_DIR}/moodle-database.sql"

sudo zip -r "${now}.zip" "${BACKUP_DIR}/"
sudo mv"${now}.zip" "${BACKUPS_BASE_DIR}"

if [ "${POST_DELETE}" = true ]; then
  delete_dir "${BACKUP_DIR}"
fi

echo -e "\e[1;32m Backup ${now} complete! \e[0m"
