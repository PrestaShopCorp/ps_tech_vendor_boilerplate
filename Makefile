.PHONY: help build version zip zip-local zip-inte zip-prod build test composer-validate lint php-lint lint-fix phpstan phpstan-baseline docker-php-lint docker-phpstan
PHP = $(shell command -v php >/dev/null 2>&1 || { echo >&2 "PHP is not installed."; exit 1; } && which php)
VERSION ?= $(shell git describe --tags 2> /dev/null || echo "0.0.0")
SEM_VERSION ?= $(shell echo ${VERSION} | sed 's/^v//')
PACKAGE ?= ps_tech_vendor_boilerplate-${VERSION}
BUILDPLATFORM ?= linux/amd64
TESTING_DOCKER_IMAGE ?= ps-eventbus-testing:latest
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
zip: zip-inte zip-prod
dist:
	@mkdir -p ./dist
.env.inte:
	@echo ".env.inte file is missing, please create it. Exiting" && exit 1;
.env.prod:
	@echo ".env.prod file is missing, please create it. Exiting" && exit 1;
.env.local:
	@echo ".env.local file is missing, please create it. Exiting" && exit 1;

# target: zip-local                              - Bundle a local E2E integrable zip
zip-local: vendor dist .env.local
	cp .env.local .env
	@$(call zip_it,.env.local,${PACKAGE}_local.zip)

# target: zip-inte                               - Bundle an integration zip
zip-inte: vendor dist .env.inte
	cp .env.inte .env
	@$(call zip_it,.env.inte,${PACKAGE}_integration.zip)

# target: zip-prod                               - Bundle a production zip
zip-prod: vendor dist .env.prod
	cp .env.prod .env
	@$(call zip_it,.env.prod,${PACKAGE}.zip)


define zip_it
$(eval TMP_DIR := $(shell mktemp -d))
mkdir -p ${TMP_DIR}/ps_tech_vendor_boilerplate;
cp -r $(shell cat .zip-contents) ${TMP_DIR}/ps_tech_vendor_boilerplate;
DIST_DIR=${TMP_DIR}/ps_tech_vendor_boilerplate ./tools/interpolate.sh;
cd ${TMP_DIR} && zip -9 -r $2 ./ps_tech_vendor_boilerplate;
mv ${TMP_DIR}/$2 ./dist;
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

vendor/bin/php-cs-fixer: composer.phar
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
test: composer-validate lint php-lint phpstan

# target: composer-validate                      - Validates composer.json and composer.lock
composer-validate: vendor
	@./composer.phar validate --no-check-publish

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

# target: phpstan                                - Run phpstan
phpstan: vendor/bin/phpstan prestashop/prestashop-${PS_VERSION}
	_PS_ROOT_DIR_=${PS_ROOT_DIR} vendor/bin/phpstan analyse --memory-limit=256M --configuration=./tests/phpstan/phpstan.neon;

# target: phpstan-baseline                       - Generate a phpstan baseline to ignore all errors
phpstan-baseline: prestashop/prestashop-${PS_VERSION} vendor/bin/phpstan
	_PS_ROOT_DIR_=${PS_ROOT_DIR} vendor/bin/phpstan analyse --generate-baseline --memory-limit=256M --configuration=./tests/phpstan/phpstan.neon;


# target: docker-php-lint                        - Lint the code with php in docker
docker-php-lint:
	docker build --build-arg BUILDPLATFORM=${BUILDPLATFORM} --build-arg PHP_VERSION=${PHP_VERSION} -t ${TESTING_DOCKER_IMAGE} -f dev-tools.Dockerfile .;
	docker run --rm -v $(shell pwd):/src ${TESTING_DOCKER_IMAGE} php-lint;

# target: docker-phpstan                         - Run phpstan in docker
docker-phpstan: prestashop/prestashop-${PS_VERSION}
	docker build --build-arg BUILDPLATFORM=${BUILDPLATFORM} --build-arg PHP_VERSION=${PHP_VERSION} -t ${TESTING_DOCKER_IMAGE} -f dev-tools.Dockerfile .;
	docker run --rm -e _PS_ROOT_DIR_=/src/prestashop/prestashop-${PS_VERSION} -v $(shell pwd):/src ${TESTING_DOCKER_IMAGE} phpstan;
