#!/bin/sh

#sudo ./moodle_install_begin_clean.sh root password moodle localhost moodle_user moodle_user_password /opt/moodle /var/www/moodle MOODLE_311_STABLE /var/www/moodledata

#db_root_user="root"
#db_root_password="cts_ysp_lms_db_root_password_HVt!JqT7"

#db_moodle="ysp_moodle_db"
#db_moodle_host="localhost"
#db_moodle_user="ysp_moodle_db_user"
#db_moodle_user_password="ysp_moodle_db_user_password_Ph&PYe5N"

#apache_webroot="/var/www/"

#MOODLE_CORE="/opt/moodle"
#moodle_root="/var/www/moodle"
#moodle_branch_name="MOODLE_311_STABLE"
#moodle_data="/var/www/moodledata"

usage() {
  cat <<_EOF_
Usage: ${0} "ROOT USERNAME" "ROOT PASSWORD" "MOODLE DATABASE NAME" "MOODLE DATABASE HOST" "MOODLE DATABASE USER" "MOODLE DATABASE USER PASSWORD" "MOODLE CORE CODE DIRECTORY" "MOODLE ROOT" "MOODLE BRANCH NAME" "MOODLEDATA DIRECTORY"
  with "ROOT PASSWORD" the password for the database root user. Use quotes if your password contains spaces or other special characters.
       "MOODLE DATABASE NAME" the desired name for the moodle database.
       "MOODLE DATABASE HOST" the desired host for the the moodle database.
_EOF_
}

delete_dir() {
  for i in "$@"; do
    echo "Deleting $i ..."
    sudo rm -rf $i
  done
}

MOODLE_CORE=NULL
MOODLE_ROOT=NULL
MOODLE_BRANCH_NAME="MOODLE_311_STABLE"
MOODLE_DATA=NULL

MOODLE_REPO="git://git.moodle.org/moodle.git"
YES_ALL=false

while [ "$1" != "" ]; do
  PARAM=$(echo $1 | awk -F= '{print $1}')
  VALUE=$(echo $1 | awk -F= '{print $2}')
  case $PARAM in
  -h | --help)
    usage
    exit
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

if [ -d "${MOODLE_CORE}" ]; then
  echo "${MOODLE_CORE} directory already exists. This may cause problems when cloning the Moodle repository causing
  the install process to fail."
  echo "It is highly recommended that you delete the contents of ${MOODLE_CORE} before moving on."
  if [ $YES_ALL = true ]; then
    continue="Y"
  else
    read -p "Do you want to delete the current contents of ${MOODLE_CORE}? (Y/N): " continue
  fi
  case $continue in
    [Yy]*)
      delete_dir "${MOODLE_CORE}"
      ;;
    [Nn]*)
      ;;
    *)
      echo "Please enter Yes(Y) or No (N)"
      ;;
    esac
fi

echo "cloning moodle git repository..."
sudo git clone "${MOODLE_REPO}" "${MOODLE_CORE}"

echo "available moodle branches:"
sudo git -C "${MOODLE_CORE}" branch -a

echo "configuring moodle branch '${MOODLE_BRANCH_NAME}'..."
sudo git -C "${MOODLE_CORE}" branch --track "${MOODLE_BRANCH_NAME}" origin/"${MOODLE_BRANCH_NAME}"

echo "checking out moodle branch '${MOODLE_BRANCH_NAME}'..."
sudo git -C "${MOODLE_CORE}" checkout "${MOODLE_BRANCH_NAME}"

if [ -d "${MOODLE_ROOT}" ]; then
  echo "${MOODLE_ROOT} directory already exists. This may cause problems when creating the new moodle root directory,
  '${MOODLE_ROOT}'."
  echo "It is highly recommended that you delete the contents of ${MOODLE_ROOT} before moving on."
  if [ $YES_ALL = true ]; then
    continue="Y"
    delete_dir "${MOODLE_ROOT}"
  else
    read -p "Do you want to delete the current contents of ${MOODLE_ROOT}? (Y/N): " continue
  fi
  case $continue in
   [Yy]*)
     delete_dir "${MOODLE_ROOT}"
    ;;
  [Nn]*) ;;
  *)
    echo "Please enter Yes(Y) or No (N)"
    ;;
  esac
fi

echo "copying ${MOODLE_CORE} code into ${MOODLE_ROOT} ..."
sudo cp -R "${MOODLE_CORE}" "${MOODLE_ROOT}"

if [ -d "${MOODLE_DATA}" ]; then
  echo "${MOODLE_DATA} directory already exists. This may cause problems when creating the moodledata directory,
  '${MOODLE_DATA}'."
  echo "It is highly recommended that you delete the contents of ${MOODLE_DATA} before moving on."
  if [ $YES_ALL = true ]; then
    continue="Y"
  else
    read -p "Do you want to delete the current contents of ${MOODLE_DATA}? (Y/N): " continue
  fi
  case $continue in
    [Yy]*)
      delete_dir "${MOODLE_DATA}"
      ;;
    [Nn]*) ;;
    *)
      echo "Please enter Yes(Y) or No (N)"
      ;;
  esac
fi

echo "creating moodledata directory at ${MOODLE_DATA} ..."
sudo mkdir "${MOODLE_DATA}"
sudo chown -R www-data "${MOODLE_DATA}"
sudo chmod -R 777 "${MOODLE_DATA}"

echo "making moodle root writeable..."
sudo chmod -R 777 "${MOODLE_ROOT}"
