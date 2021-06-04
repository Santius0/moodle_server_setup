import os
import invoke

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def banner(m, start=False):
    if start:
        print("==================================================")
    print("= {} ".format(m))
    if not start:
        print("==================================================")


def msg(m, start=False):
    print("%s%s" % (m, '......' if start else ''))


@invoke.task
def build_moodle(c):
    """ Build moodle implementation"""
    banner("Building Moodle", start=True)

    msg('adding php7 ppa', start=True)
    invoke.run("sudo add-apt-repository ppa:ondrej/php")
    invoke.run("sudo apt-get update")
    msg('Successfully added php7 ppa', start=False)

    msg("installing moodle pre-requisites", start=True)
    invoke.run("sudo apt install apache2 mysql-client mysql-server php libapache2-mod-php -y")
    msg("moodle pre-requisites installed", start=False)

    msg("installing extra apache2 plugins", start=True)
    invoke.run("sudo apt install graphviz aspell ghostscript clamav php7.4-pspell php7.4-curl php7.4-gd php7.4-intl php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-ldap php7.4-zip php7.4-soap php7.4-mbstring -y")
    msg("extra apache2 plugins installed", start=False)

    msg("restarting apache2", start=True)
    invoke.run("sudo service apache2 restart")
    msg("apache2 restart successful", start=True)

    msg("installing git", start=True)
    invoke.run("sudo apt install git -y")
    msg("git successfully installed", start=True)

    msg("cloning moodle repository to /opt/moodle", start=True)
    invoke.run("sudo git clone git://git.moodle.org/moodle.git /opt/moodle")
    msg("moodle repository successfully cloned to /opt/moodle", start=True)

    msg("configuring moodle branch MOODLE_39_STABLE", start=True)
    invoke.run("sudo git -C /opt/moodle branch -a")
    invoke.run("sudo git -C /opt/moodle branch --track MOODLE_39_STABLE origin/MOODLE_39_STABLE")
    invoke.run("sudo git -C /opt/moodle checkout MOODLE_39_STABLE")
    msg("MOODLE_39_STABLE successfully tracked", start=True)

    msg("copying moodle core code from /opt/moodle to /var/www/html/moodle", start=True)
    invoke.run("sudo cp -R /opt/moodle /var/www/html/")
    msg("/opt/moodle copied to /var/www/html/moodle", start=False)

    msg("creating moodledata directory /var/www/moodledata", start=True)
    invoke.run("sudo mkdir /var/www/moodledata")
    msg("successfully creating moodledata directory /var/www/moodledata", start=False)

    banner("*Complete", start=False)
