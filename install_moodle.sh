#!/bin/bash

YES_ALL=false

usage() {
    echo "sample usage: ${0} -c --moodle-core=/opt/moodle --moodle-root=/var/www/html/moodle --moodle-data=/var/www/moodledata --moodle-repo=git://git.moodle.org/moodle.git --moodle-branch=MOODLE_39_STABLE -y"
    echo ""
    printf "\t -h --help\n\n"
#    printf "\t -c --clean=%s\n" "${CLEAN_INSTALL}"
#    printf "\t -b --backup=%s\n" "${BACKUP_INSTALL}"
#    printf "\t --mysql_secure_install=%s\n" "${MYSQL_SECURE_INSTALL}"
#    printf "\t --config-file='%s'\n" "${NULL}"
    echo ""
}

delete_dir() {
  for i in "$@"; do
    echo "Deleting $i ..."
    sudo rm -rf "$i"
  done
}

add_ppa() {
  for i in "$@"; do
    grep -h "^deb.*$i" /etc/apt/sources.list.d/* >/dev/null 2>&1
    # shellcheck disable=SC2181
    if [ $? -ne 0 ]; then
      echo "adding ppa:$i"
      sudo add-apt-repository ppa:"$i" -y
    else
      echo "ppa:$i already exists on system"
    fi
  done
}

remove_ppa() {
  for i in "$@"; do
    grep -h "^deb.*$i" /etc/apt/sources.list.d/* >/dev/null 2>&1
    # shellcheck disable=SC2181
    if [ $? -ne 0 ]; then
      echo "ppa:$i does not exist on system"
    else
      echo "removing ppa:$i"
      sudo add-apt-repository --remove -y ppa:"$i"
    fi
  done
}

create_database() {
  db_admin_user=${1}
  db_admin_password=${2}
  db_moodle=${3}
  echo ""
  mysql --user="${db_admin_user}" --password="${db_admin_password}" <<_EOF_
    DROP DATABASE IF EXISTS ${db_moodle};
    CREATE DATABASE ${db_moodle} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
_EOF_

}

create_database_user() {
  db_admin_user=${1}
  db_admin_password=${2}
  db_moodle=${3}
  db_moodle_host=${4}
  db_moodle_user=${5}
  db_moodle_user_password=${6}
  mysql --user="${db_admin_user}" --password="${db_admin_password}" <<_EOF_
    DROP User IF EXISTS '${db_moodle_user}'@'${db_moodle_host}';
    CREATE User '${db_moodle_user}'@'${db_moodle_host}' IDENTIFIED BY '${db_moodle_user_password}';
    GRANT SELECT,INSERT,UPDATE,DELETE,CREATE,CREATE TEMPORARY TABLES,DROP,INDEX,ALTER ON ${db_moodle}.* TO '${db_moodle_user}'@'${db_moodle_host}';
_EOF_
}

clean_build_moodle_database() {
  # shellcheck disable=SC2039
  read -rp "Enter the name of the Moodle database (default='moodle'): " db_moodle
  if [ -z "$db_moodle" ]; then
    db_moodle="moodle"
  fi
  # shellcheck disable=SC2039
  read -rp "Enter the name of the Moodle database host (default='localhost'): " db_moodle_host
  if [ -z "$db_moodle_host" ]; then
    db_moodle_host="localhost"
  fi
  echo "The database '${db_moodle}'@'${db_moodle_host}' will be completely wiped and recreated."

  if [ "${YES_ALL}" = false ]; then
    while true; do
      # shellcheck disable=SC2039
      read -r -p "Are you sure you want to continue? Y/N: " continue
      case $continue in
      [Yy]*)
        break
        ;;
      [Nn]*)
        echo "skipping moodle database rebuild..."
        return
        ;;
      *)
        echo "Please select either Yes(Y) or No(N)"
        ;;
      esac
    done
  fi

  echo "Please provide the requested credentials to continue"
  read -rsp "MySql root password: " db_root_password
  echo ""
  # shellcheck disable=SC2039
  read -rp "Username of '${db_moodle}' user (default='moodle_user'): " db_moodle_user
  if [ -z "$db_moodle_user" ]; then
    db_moodle_user="moodle_user"
  fi
  # shellcheck disable=SC2039
  read -rsp "Password for user '${db_moodle_user}': " db_moodle_user_password
  create_database "root" "${db_root_password}" "${db_moodle}"
  create_database_user "root" "${db_root_password}" "${db_moodle}" "${db_moodle_host}" "${db_moodle_user}" "${db_moodle_user_password}"
}

clone_repo() {
  moodle_repo=${1}
  moodle_core=${2}
  if [ -d "${moodle_core}" ]; then
    echo -e "\e${moodle_core} directory already exists. This may cause problems when cloning the Moodle repository causing the install process to fail.\e[0m"
    echo -e "\eIt is highly recommended that you delete the contents of ${moodle_core} before moving on.\e[0m"
    if [ "${YES_ALL}" = true ]; then
      do_delete=true
    else
      while true; do
        # shellcheck disable=SC2039
        read -r -p "Do you want to delete the current contents of ${moodle_core}? (Y/N): " continue
        case $continue in
        [Yy]*)
          do_delete=true
          break
          ;;
        [Nn]*)
          do_delete=false
          break
          ;;
        *)
          echo "Please enter Yes(Y) or No (N)"
          ;;
        esac
      done
    fi
    if [ ${do_delete} = true ]; then
      delete_dir "${moodle_core}"
    else
      echo "Skipping deletion of existing moodle_core directory '${moodle_core}' ..."
    fi
  fi
  echo "cloning moodle git repository..."
  sudo git clone "${moodle_repo}" "${moodle_core}"
}

checkout_repo_branch() {
  moodle_core=${1}
  moodle_branch_name=${2}

  echo "available moodle branches:"
  sudo git -C "${moodle_core}" branch -a

  echo "configuring moodle branch '${moodle_branch_name}'..."
  sudo git -C "${moodle_core}" branch --track "${moodle_branch_name}" origin/"${moodle_branch_name}"

  echo "checking out moodle branch '${moodle_branch_name}'..."
  sudo git -C "${moodle_core}" checkout "${moodle_branch_name}"
}

install_moodle_dirs() {
  moodle_core=${1}
  moodle_root=${2}
  moodle_data=${3}

  if [ -d "${moodle_root}" ]; then
    echo -e "\e[1;33m ${moodle_root} directory already exists. This may cause problems when creating the new moodle root directory, '${moodle_root}'.\e[0m"
    echo -e "\e[1;33m It is highly recommended that you delete the contents of ${moodle_root} before moving on.\e[0m"
    if [ "${YES_ALL}" = true ]; then
      do_delete=true
    else
      while true; do
        # shellcheck disable=SC2039
        read -r -p "Do you want to delete the current contents of ${moodle_root}? (Y/N): " continue
        case $continue in
        [Yy]*)
          do_delete=true
          break
          ;;
        [Nn]*)
          do_delete=false
          break
          ;;
        *)
          echo "Please enter Yes(Y) or No (N)"
          ;;
        esac
      done
    fi
    if [ $do_delete = true ]; then
      delete_dir "${moodle_root}"
    else
      echo "Skipping deletion of existing moodle_root folder '${moodle_root} ..."
    fi
  fi

  echo "copying ${moodle_core} code into ${moodle_root} ..."
  sudo cp -R "${moodle_core}" "${moodle_root}"

  if [ -d "${moodle_data}" ]; then
    echo -e "\e[1;33m ${moodle_data} directory already exists. This may cause problems when creating the moodledata directory, '${moodle_data}'. \e[0m"
    echo -e "\e[1;33m It is highly recommended that you delete the contents of ${moodle_data} before moving on. \e[0m"
    if [ "${YES_ALL}" = true ]; then
      do_delete=true
    else
      while true; do
        # shellcheck disable=SC2039
        read -r -p "Do you want to delete the current contents of ${moodle_data}? (Y/N): " continue
        case $continue in
        [Yy]*)
          do_delete=true
          break
          ;;
        [Nn]*)
          do_delete=false
          break
          ;;
        *)
          echo "Please enter Yes(Y) or No (N)"
          ;;
        esac
      done
    fi
    if [ $do_delete = true ]; then
      delete_dir "${moodle_data}"
    else
      echo "Skipping deletion of existing moodledata folder '${moodle_data} ..."
    fi
  fi

  echo "creating moodledata directory at ${moodle_data} ..."
  sudo mkdir "${moodle_data}"
  sudo chown -R www-data "${moodle_data}"
  sudo chmod -R 777 "${moodle_data}"

#  echo "assigning moodle_root permissions: u=rwx, g=rx, o=rx ..."
#  sudo chmod -R 0755 "${moodle_root}"

  echo "assigning moodle_root permissions: u=rwx, g=rwx, o=rwx ..."
  sudo chmod -R 0777 "${moodle_root}"
}

while [ "$1" != "" ]; do
  # shellcheck disable=SC2006
  PARAM=$(echo "$1" | awk -F= '{print $1}')
  # shellcheck disable=SC2006
  VALUE=$(echo "$1" | awk -F= '{print $2}')
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
  -mc | --moodle-core)
    MOODLE_CORE=$VALUE
    ;;
  -mr | --moodle-root)
    MOODLE_ROOT=$VALUE
    ;;
  -mb | --moodle-branch)
    MOODLE_BRANCH_NAME=$VALUE
    ;;
  -md | --moodle-data)
    MOODLE_DATA=$VALUE
    ;;
  -mre | --moodle-repo)
    MOODLE_REPO=$VALUE
    ;;
  --config-file)
    CONFIG_FILE=$VALUE
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

if [ -z $CLEAN_INSTALL ] && [ -z $BACKUP_INSTALL ]; then
  echo "ERROR: One of -c --clean or -b --backup is required"
  exit 1
fi

if [ "${CLEAN_INSTALL}" = "${BACKUP_INSTALL}" ]; then
  echo "ERROR: Use only one of -c --clean or -b --backup"
  exit 1
fi

if [ -z "$MOODLE_CORE" ]; then
  echo "-c/--core is required."
  usage
  exit 2
fi

if [ -z "$MOODLE_ROOT" ]; then
  echo "-r/--root is required."
  usage
  exit 2
fi

if [ -z "$MOODLE_BRANCH_NAME" ]; then
  echo "-b/--branch is required."
  usage
  exit 2
fi

if [ -z "$MOODLE_DATA" ]; then
  echo "-d/--data is required."
  usage
  exit 2
fi

if [ "${YES_ALL}" = true ]; then
  YES_FLAG="-y"
else
  YES_FLAG=""
fi

add_ppa ondrej/php
sudo apt-get update

# installing moodle pre-requisites
sudo apt-get install php7.4 "${YES_FLAG}"
sudo apt-get install apache2 "${YES_FLAG}"
sudo apt-get install mysql-client "${YES_FLAG}"
sudo apt-get install mysql-server "${YES_FLAG}"
sudo apt-get install libapache2-mod-php7.4 "${YES_FLAG}"

# installing apache2 and php plugins"
sudo apt-get install graphviz "${YES_FLAG}"
sudo apt-get install aspell "${YES_FLAG}"
sudo apt-get install ghostscript "${YES_FLAG}"
sudo apt-get install clamav "${YES_FLAG}"
sudo apt-get install php7.4-pspell "${YES_FLAG}"
sudo apt-get install php7.4-curl "${YES_FLAG}"
sudo apt-get install php7.4-gd "${YES_FLAG}"
sudo apt-get install php7.4-intl "${YES_FLAG}"
sudo apt-get install php7.4-mysql "${YES_FLAG}"
sudo apt-get install php7.4-xml "${YES_FLAG}"
sudo apt-get install php7.4-xmlrpc "${YES_FLAG}"
sudo apt-get install php7.4-ldap "${YES_FLAG}"
sudo apt-get install php7.4-zip "${YES_FLAG}"
sudo apt-get install php7.4-soap "${YES_FLAG}"
sudo apt-get install php7.4-mbstring "${YES_FLAG}"

# restarting apache2 service
sudo service apache2 restart

# installing git
sudo apt-get install git "${YES_FLAG}"

echo "CLEAN_INSTALL=${CLEAN_INSTALL}"
# shellcheck disable=SC2236
if [ ! -z $CLEAN_INSTALL ]; then
  echo -e "\e[1;32m BEGINNING CLEAN INSTALL OR MOODLE!\e[0m"
  echo -e "\e[1;33m You are about to do a clean install of the moodle system. This is require overwriting any identical moodle directories detected. It will also erase and recreate the specified moodle user and database.\e[0m"
  if [ "${YES_ALL}" = false ]; then
    while true; do
      read -rp "Are you sure you'd like to continue? (Y/N): " continue
      case $continue in
      [Yy]*)
        break
        ;;
      [Nn]*)
        echo "exiting..."
        exit
        ;;
      *)
        echo "Please select Yes(Y) or No(N)"
        ;;
      esac
    done
  fi
  clean_build_moodle_database
  clone_repo "${MOODLE_REPO}" "${MOODLE_CORE}"
  checkout_repo_branch "${MOODLE_CORE}" "${MOODLE_BRANCH_NAME}"
  install_moodle_dirs "${MOODLE_CORE}" "${MOODLE_ROOT}" "${MOODLE_DATA}"
  if [ ! -z "${CONFIG_FILE}" ]; then
    echo "copy over provided config.php file"
    sudo cp "${CONFIG_FILE}" "${MOODLE_ROOT}/config.php"
    echo "assigning moodle_root permissions: u=rwx, g=rx, o=rx ..."
    sudo chmod -R 0755 "${MOODLE_ROOT}"
  else
    echo -e "\e[1;32m Moodle Installation Completed Successfully \e[0m"
    echo -e "\e[1;33m It is highly recommended that you assign moodle_root directory '${MOODLE_ROOT}' 755 permissions after config.php is successfully written to it. \e[0m"
  fi
fi

# shellcheck disable=SC2236
if [ ! -z "${BACKUP_INSTALL}" ]; then
  echo "install from backup no yet implemented"
fi

sudo service apache2 restart