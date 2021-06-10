#!/bin/sh

# sudo ./moodle_install_end_clean.sh /var/www/moodle
#                     or
# sudo ./moodle_install_end_clean.sh /var/www/moodle ~/config.php

MOODLE_ROOT=NULL
CONFIG_FILE=NULL

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        -mr | --moodle-root)
            MOODLE_ROOT=$VALUE
            ;;
        -conf | --config-file)
            CONFIG_FILE=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done


if [ -z "$MOODLE_ROOT" ]; then
  echo "-r/--root is required."
  usage
  exit 2
fi

# shellcheck disable=SC2236
if [ ! -z "$CONFIG_FILE" ]; then
  if [ -d "${MOODLE_ROOT}/config.php" ]; then
    echo "${MOODLE_ROOT}/config.php directory already exists."
    # shellcheck disable=SC2039
    read -r -p "Do you want to overwrite the current config.php file? (Y/N): " yn
    case $yn in
      [Yy]* )
        echo "copying preset config file '${CONFIG_FILE}' to ${MOODLE_ROOT}/config.php ...";
        sudo rm -f "${MOODLE_ROOT}"/config.php;
        sudo cp "${CONFIG_FILE}" "${MOODLE_ROOT}"/config.php;
        ;;
      [Nn]* )
        ;;
      * ) echo "Please answer yes or no.";;
    esac
  else
    echo "${MOODLE_ROOT}/config.php does not exist"
    echo "copying preset config file '${CONFIG_FILE}' to ${MOODLE_ROOT}/config.php ..."
    sudo cp "${CONFIG_FILE}" "${MOODLE_ROOT}"/config.php;
  fi
else
  echo "-conf/--config-file is required."
  usage
  exit 2
fi

sudo chmod -R 755 /var/www/html/moodle
