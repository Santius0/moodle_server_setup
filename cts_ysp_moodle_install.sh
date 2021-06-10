#!/bin/sh

CLEAN_INSTALL=true
BACKUP_INSTALL=false

MYSQL_SECURE_INSTALL=false
YES_FLAG=""

usage() {
    echo "${0}"
    printf "\t -h --help\n"
    printf "\t -c --clean=%s\n" "${CLEAN_INSTALL}"
    printf "\t -b --backup=%s\n" "${BACKUP_INSTALL}"
    printf "\t --mysql_secure_install=%s\n" "${MYSQL_SECURE_INSTALL}"
    printf "\t --config-file='%s'\n" "${NULL}"
    echo ""
}

while [ "$1" != "" ]; do
    # shellcheck disable=SC2006
    PARAM=`echo "$1" | awk -F= '{print $1}'`
    # shellcheck disable=SC2006
    VALUE=`echo "$1" | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -c | --clean)
            CLEAN_INSTALL=true
            ;;
        -b | --backup)
            BACKUP_INSTALL=true
            ;;
        --mysql-secure-install)
            MYSQL_SECURE_INSTALL=true
            ;;
        --config-file)
            CONFIG_FILE=$VALUE
            ;;
        -y | -Y)
            YES_FLAG="-Y"
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

if [ "${CLEAN_INSTALL}" = "${BACKUP_INSTALL}" ]; then
#  echo "${CLEAN_INSTALL}"
#  echo "${BACKUP_INSTALL}"
  echo "ERROR: Use only one of -c (--clean) or -b (--backup)"
  exit 1
fi

sudo /bin/bash ./scripts/install_moodle_prerequisites.sh


if [ "${MYSQL_SECURE_INSTALL}" = true ]; then
  sudo /bin/bash ./scripts/run_mysql_secure_installation.sh
fi

if [ "${CLEAN_INSTALL}" = true ]; then
  echo "CLEAN INSTALL!"
  echo "You are about to do a clean install of the moodle system. This is require overwriting any identical moodle directories detected. It will also erase and recreate the specified moodle user and database."
  # shellcheck disable=SC2236
  if [ "${YES_FLAG}" = "-Y" ]; then
    continue=YES_FLAG
  else
      while true; do
      # shellcheck disable=SC2039
      read -r -p "Are you sure you'd like to continue? (Y/N): " continue
      case $continue in
        [Yy]* )
          break
          ;;
        [Nn]* )
          echo "exiting..."
          exit
          ;;
        * )
          echo "Please select Yes(Y) or No(N)"
          ;;
      esac
    done
  fi
  sudo /bin/bash ./scripts/clean_build_moodle_database.sh ${YES_FLAG}
#  sudo /bin/bash ./scripts/moodle_install_begin_clean.sh --moodle-core="/opt/moodle" --moodle-root="/var/www/moodle" --moodle-branch="MOODLE_311_STABLE" --moodle-data="/var/www/moodledata" "${YES_FLAG}"
  sudo /bin/bash ./scripts/moodle_install_begin_clean.sh --moodle-core="/opt/moodle" --moodle-root="/var/www/html/moodle" --moodle-branch="MOODLE_39_STABLE" --moodle-data="/var/www/moodledata" "${YES_FLAG}"
  # shellcheck disable=SC2236
  if [ ! -z "${CONFIG_FILE}" ]; then
    sudo /bin/bash ./scripts/moodle_install_end_clean.sh --moodle-root="/var/www/html/moodle" --config-file="${CONFIG_FILE}" "${YES_FLAG}"
  fi
elif [ "${BACKUP_INSTALL}" = true ]; then
  echo "doing backup install"
fi
