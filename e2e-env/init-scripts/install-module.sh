#!/bin/sh
#
# This is an init-script for prestashop-flashlight.
#
# Storing a folder in /var/www/html/modules is not enough to register the module
# into PrestaShop, hence why we have to call the console install CLI.
#
set -eu

MODULE_NAME="ps_tech_vendor_boilerplate"
PS_EVENTBUS_VERSION="v3.0.8"

error() {
  printf "\e[1;31m%s\e[0m\n" "${1:-Unknown error}"
  exit "${2:-1}"
}

run_user() {
  sudo -g www-data -u www-data -- "$@"
}

ps_accounts_mock_install() {
  echo "* [ps_accounts_mock] downloading..."
  wget -q -O /tmp/ps_accounts.zip "https://github.com/PrestaShopCorp/ps_accounts_mock/releases/download/0.0.0/ps_accounts.zip"
  echo "* [ps_accounts_mock] unziping..."
  run_user unzip -qq /tmp/ps_accounts.zip -d /var/www/html/modules
  echo "* [ps_accounts_mock] installing the module..."
  cd "$PS_FOLDER"
  run_user php -d memory_limit=-1 bin/console prestashop:module --no-interaction install "ps_accounts"
}

module_install() {
  # Some explanations are required here:
  #
  # If you look closer to the ./docker-compose.yml prestashop service, you will
  # see multiple mounts on the same files:
  # - ..:/var/www/html/modules/ps_tech_vendor_boilerplate:rw        => mount all the sources
  # - /var/www/html/modules/ps_tech_vendor_boilerplate/vendor       => void the specific vendor dir, makint it empty
  # - /var/www/html/modules/ps_tech_vendor_boilerplate/tools/vendor => void the specific vendor dev dir, making it empty
  #
  # That said, we now want our container to have RW access on these directories,
  # and to install the required composer dependencies for the module to work.
  #
  # Other scenarios could be imagined, but this is the best way to avoid writes on a mounted volume,
  # which would not work on a Linux environment (binding a volume), as opposed to a Windows or Mac one (NFS mount).
  chown www-data:www-data ./modules/$MODULE_NAME/vendor
  chown www-data:www-data ./modules/$MODULE_NAME/tools/vendor
  run_user composer install -n -d ./modules/$MODULE_NAME

  echo "* [module_install] installing the module..."
  cd "$PS_FOLDER"
  run_user php -d memory_limit=-1 bin/console prestashop:module --no-interaction install "$MODULE_NAME"
}

ps_eventbus_Install() {
  echo "* [ps_eventbus] downloading..."
  wget -q -O /tmp/ps_eventbus.zip "https://github.com/PrestaShopCorp/ps_eventbus/releases/download/$PS_EVENTBUS_VERSION/ps_eventbus-$PS_EVENTBUS_VERSION.zip"
  echo "* [ps_eventbus] unziping..."
  run_user unzip -qq /tmp/ps_eventbus.zip -d /var/www/html/modules
  echo "* [ps_eventbus] installing the module..."
  cd "$PS_FOLDER"
  run_user php -d memory_limit=-1 bin/console prestashop:module --no-interaction install "ps_eventbus"
}

ps_accounts_mock_install
ps_eventbus_Install
module_install

