.PHONY: help build version zip build test composer-validate lint php-lint lint-fix phpunit phpstan phpstan-baseline docker-php-lint
PHP = $(shell command -v php >/dev/null 2>&1 || { echo >&2 "PHP is not installed."; exit 1; } && which php)
VERSION ?= $(shell git describe --tags 2> /dev/null || echo "0.0.0")
SEM_VERSION ?= $(shell echo ${VERSION} | sed 's/^v//')
PACKAGE ?= ps_tech_vendor_boilerplate-${VERSION}
BUILDPLATFORM ?= linux/amd64
TESTING_DOCKER_IMAGE ?= ps-eventbus-testing:latest
#TESTING_DOCKER_BASE_IMAGE ?= phpdockerio/php80-cli
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

vendor/bin/php-cs-fixer: composer.phar
	./composer.phar install --ignore-platform-reqs

# target: test                                   - Static and unit testing
test: composer-validate lint php-lint

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

# target: docker-php-lint                        - Lint the code with php in docker
docker-php-lint:
	docker build --build-arg BUILDPLATFORM=${BUILDPLATFORM} --build-arg PHP_VERSION=${PHP_VERSION} -t ${TESTING_DOCKER_IMAGE} -f dev-tools.Dockerfile .;
	docker run --rm -v $(shell pwd):/src ${TESTING_DOCKER_IMAGE} php-lint;
