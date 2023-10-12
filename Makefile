.PHONY: help build version zip zip-inte zip-preprod zip-prod build test composer-validate lint php-lint lint-fix phpunit phpstan phpstan-baseline docker-test docker-lint docker-lint docker-phpunit docker-phpstan
PHP = $(shell command -v php >/dev/null 2>&1 || { echo >&2 "PHP is not installed."; exit 1; } && which php)
VERSION ?= $(shell git describe --tags 2> /dev/null || echo "0.0.0")
SEM_VERSION ?= $(shell echo ${VERSION} | sed 's/^v//')
PACKAGE ?= ps_tech_vendor_boilerplate-${VERSION}
BUILDPLATFORM ?= linux/amd64
TESTING_DOCKER_IMAGE ?= ps-eventbus-testing:latest
TESTING_DOCKER_BASE_IMAGE ?= phpdockerio/php80-cli
PHP_VERSION ?= 8.2
PS_VERSION ?= 1.7.8.7
PS_ROOT_DIR ?= $(shell pwd)/prestashop/prestashop-${PS_VERSION}

# target: default                                - Calling build by default
default: build

# target: help                                   - Get help on this file
help:
	@egrep "^#" Makefile

# target: clean                                  - Clean up the repository
clean:
	git -c core.excludesfile=/dev/null clean -X -d -f

# target: version                                - Replace version in files
version:
	@echo "...$(VERSION)..."
	@sed -i.bak -e "s/\(VERSION = \).*/\1\'${SEM_VERSION}\';/" ps_tech_vendor_boilerplate.php
	@sed -i.bak -e "s/\($this->version = \).*/\1\'${SEM_VERSION}\';/" ps_tech_vendor_boilerplate.php
	@sed -i.bak -e "s|\(<version><!\[CDATA\[\)[0-9a-z.-]\{1,\}]]></version>|\1${SEM_VERSION}]]></version>|" config.xml
	@rm -f ps_tech_vendor_boilerplate.php.bak config.xml.bak

# target: zip                                    - Make zip bundles
zip: vendor dist
	@$(call zip_it,${PACKAGE}.zip)
dist:
	@mkdir -p ./dist

define zip_it
$(eval TMP_DIR := $(shell mktemp -d))
mkdir -p ${TMP_DIR}/ps_tech_vendor_boilerplate;
cp -r $(shell cat .zip-contents) ${TMP_DIR}/ps_tech_vendor_boilerplate;
cd ${TMP_DIR} && zip -9 -r $1 ./ps_tech_vendor_boilerplate;
mv ${TMP_DIR}/$1 ./dist;
rm -rf ${TMP_DIR:-/dev/null};
endef

# target: build                                  - Setup PHP & Node.js locally
build: vendor

composer.phar:
	@php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');";
	@php composer-setup.php;
	@php -r "unlink('composer-setup.php');";

vendor: composer.phar
	./composer.phar install --no-dev -o;

# ----------------------------------------------------------------


vendor/bin/php-cs-fixer: composer.phar
	./composer.phar install --ignore-platform-reqs

vendor/bin/phpunit: composer.phar
	./composer.phar install --ignore-platform-reqs

vendor/bin/phpstan: composer.phar
	./composer.phar install --ignore-platform-reqs

prestashop:
	@mkdir -p ./prestashop

prestashop/prestashop-${PS_VERSION}: prestashop composer.phar
	@if [ ! -d "prestashop/prestashop-${PS_VERSION}" ]; then \
		git clone --depth 1 --branch ${PS_VERSION} https://github.com/PrestaShop/PrestaShop.git prestashop/prestashop-${PS_VERSION}; \
		./composer.phar -d ./prestashop/prestashop-${PS_VERSION} install; \
	fi;

# target: test                                   - Static and unit testing
test: composer-validate lint php-lint phpstan phpunit translation-validate

# target: composer-validate                      - Validates composer.json and composer.lock
composer-validate: vendor
	@./composer.phar validate --no-check-publish

# target: translation-validate                   - Validates the translation files in translations/ directory
translation-validate:
	php tests/translation.test.php

# target: lint                                   - Lint the code and expose errors
lint: vendor/bin/php-cs-fixer
	@PHP_CS_FIXER_IGNORE_ENV=1 vendor/bin/php-cs-fixer fix --dry-run --diff --using-cache=no;

# target: lint-fix                               - Lint the code and fix it
lint-fix: vendor/bin/php-cs-fixer
	@PHP_CS_FIXER_IGNORE_ENV=1 vendor/bin/php-cs-fixer fix --using-cache=no;

# target: php-lint                               - Use php linter to check the code
php-lint:
	@git ls-files | grep -E '.*\.(php)' | xargs -n1 php -l -n | (! grep -v "No syntax errors" );
	@echo "php $(shell php -r 'echo PHP_VERSION;') lint passed";

# target: phpunit                                - Run phpunit tests
phpunit: vendor/bin/phpunit
	vendor/bin/phpunit --configuration=./tests/phpunit.xml;

# target: phpunit-coverage                       - Run phpunit with coverage and allure
phpunit-coverage: vendor/bin/phpunit
	php -dxdebug.mode=coverage vendor/bin/phpunit --coverage-html ./coverage-reports/coverage-html --configuration=./tests/phpunit-coverage.xml;

# target: phpstan                                - Run phpstan
phpstan: vendor/bin/phpstan prestashop/prestashop-${PS_VERSION}
	_PS_ROOT_DIR_=${PS_ROOT_DIR} vendor/bin/phpstan analyse --memory-limit=256M --configuration=./tests/phpstan/phpstan.neon;

# target: phpstan-baseline                       - Generate a phpstan baseline to ignore all errors
phpstan-baseline: prestashop/prestashop-${PS_VERSION} vendor/bin/phpstan
	_PS_ROOT_DIR_=${PS_ROOT_DIR} vendor/bin/phpstan analyse --generate-baseline --memory-limit=256M --configuration=./tests/phpstan/phpstan.neon;

# target: docker-test                            - Static and unit testing in docker
docker-test: docker-lint docker-phpstan docker-phpunit

# target: docker-lint                            - Lint the code in docker
docker-lint:
	docker build --build-arg BUILDPLATFORM=${BUILDPLATFORM} --build-arg PHP_VERSION=${PHP_VERSION} -t ${TESTING_DOCKER_IMAGE} -f dev-tools.Dockerfile .;
	docker run --rm -v $(shell pwd):/src ${TESTING_DOCKER_IMAGE} lint;

# target: docker-lint-fix                        - Lint and fix the code in docker
docker-lint-fix:
	docker build --build-arg BUILDPLATFORM=${BUILDPLATFORM} --build-arg PHP_VERSION=${PHP_VERSION} -t ${TESTING_DOCKER_IMAGE} -f dev-tools.Dockerfile .;
	docker run --rm -v $(shell pwd):/src ${TESTING_DOCKER_IMAGE} lint-fix;

# target: docker-php-lint                        - Lint the code with php in docker
docker-php-lint:
	docker build --build-arg BUILDPLATFORM=${BUILDPLATFORM} --build-arg PHP_VERSION=${PHP_VERSION} -t ${TESTING_DOCKER_IMAGE} -f dev-tools.Dockerfile .;
	docker run --rm -v $(shell pwd):/src ${TESTING_DOCKER_IMAGE} php-lint;

# target: docker-phpunit                         - Run phpunit in docker
docker-phpunit: prestashop/prestashop-${PS_VERSION}
	docker build --build-arg BUILDPLATFORM=${BUILDPLATFORM} --build-arg PHP_VERSION=${PHP_VERSION} -t ${TESTING_DOCKER_IMAGE} -f dev-tools.Dockerfile .;
	docker run --rm -e _PS_ROOT_DIR_=/src/prestashop/prestashop-${PS_VERSION} -v $(shell pwd):/src ${TESTING_DOCKER_IMAGE} phpunit;

# target: docker-phpunit-coverage                - Run phpunit in docker
docker-phpunit-coverage: prestashop/prestashop-${PS_VERSION}
	docker build --build-arg BUILDPLATFORM=${BUILDPLATFORM} --build-arg PHP_VERSION=${PHP_VERSION} -t ${TESTING_DOCKER_IMAGE} -f dev-tools.Dockerfile .;
	docker run --rm -e _PS_ROOT_DIR_=/src/prestashop/prestashop-${PS_VERSION} -v $(shell pwd):/src ${TESTING_DOCKER_IMAGE} phpunit-coverage;

# target: docker-phpstan                         - Run phpstan in docker
docker-phpstan: prestashop/prestashop-${PS_VERSION}
	docker build --build-arg BUILDPLATFORM=${BUILDPLATFORM} --build-arg PHP_VERSION=${PHP_VERSION} -t ${TESTING_DOCKER_IMAGE} -f dev-tools.Dockerfile .;
	docker run --rm -e _PS_ROOT_DIR_=/src/prestashop/prestashop-${PS_VERSION} -v $(shell pwd):/src ${TESTING_DOCKER_IMAGE} phpstan;

bps177: build-ps-177
ata177: all-tests-actions-177
rda177: run-docker-actions-177
build-ps-177:
	docker exec -i prestashop-177 sh -c "rm -rf /var/www/html/install"
	docker exec -i prestashop-177 sh -c "mv /var/www/html/admin /var/www/html/admin1"
	mysql -h 127.0.0.1 -P 9001 --protocol=tcp -u root -pprestashop prestashop < $(shell pwd)/tests/System/Seed/Database/177.sql
	docker exec -i prestashop-177 sh -c "cd /var/www/html && php  bin/console prestashop:module install eventBus"

run-docker-actions-177:
	docker-compose up -d --build --force-recreate prestashop-177

all-tests-actions-177:
	make rda177
	make bps177
	docker exec -i prestashop-177 sh -c "cd /var/www/html/modules/ps_tech_vendor_boilerplate && php vendor/bin/phpunit -c tests/phpunit.xml"

