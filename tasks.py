import os
import invoke

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def print_banner(msg):
    print("==================================================")
    print("= {} ".format(msg))


@invoke.task
def build_ibscan(c):
    """ Build ibscan implementation"""
    print_banner("Building ibscan.dll")

    invoke.run("sudo add-apt-repository ppa:ondrej/php")
    invoke.run("sudo apt-get update")
    invoke.run("sudo apt install apache2 mysql-client mysql-server php libapache2-mod-php -y")

    invoke.run("sudo apt install graphviz aspell ghostscript clamav php7.4-pspell php7.4-curl php7.4-gd php7.4-intl php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-ldap php7.4-zip php7.4-soap php7.4-mbstring -y")
    invoke.run("sudo service apache2 restart")
    invoke.run("sudo apt install git -y")

    invoke.run("sudo git clone git://git.moodle.org/moodle.git /opt/")
    invoke.run("sudo git branch -a")
    invoke.run("sudo git branch --track MOODLE_39_STABLE origin/MOODLE_39_STABLE")
    invoke.run("sudo git checkout MOODLE_39_STABLE")
    invoke.run("sudo cp -R /opt/moodle /var/www/html/")
    invoke.run("sudo mkdir /var/www/moodledata")
    print("* Complete")
