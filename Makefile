has_sauce := $(SAUCE_USERNAME)
ifndef has_sauce
test-env := test-local
else
test-env := test-sauce
endif

build: less
	@:

less_files := strider.less config.less build.less dashboard.less projects.less admin/users.less
css_files := $(patsubst %.less,public/stylesheets/css/%.css,$(less_files))

less: $(css_files)

public/stylesheets/css/%.css: public/stylesheets/less/%.less
	./node_modules/.bin/lessc $< > $@

# === Dev ===

watch:
	watch make

serve:
	@./bin/strider

## ================= Test Suite ====================================

test: test-syntax test-smoke test-unit test-browser

test-smoke:
	# TODO Smoke tests should fail _fast_ on silly errors.

test-unit:
	@./node_modules/.bin/mocha -R spec test/unit/test_middleware.js
	@./node_modules/.bin/mocha -R spec test/unit/test_ansi.js
	@./node_modules/.bin/mocha -R spec test/unit/test_api.js
	@./node_modules/.bin/mocha -R spec test/unit/test_config.js
	@./node_modules/.bin/mocha -R spec test/unit/test_utils.js

# Either test-local or test-sauce
test-browser: $(test-env)

# ===== SAUCE:

test-sauce: test-sauce-pre test-integration-sauce

test-sauce-pre:
ifndef SAUCE_ACCESS_KEY
	$(error You need env: SAUCE_ACCESS_KEY)
endif
	# Sauce Connect: https://saucelabs.com/docs/connect

test-integration-sauce:
	# --- INTEGRATION TESTING ---
	echo $$WEBDRIVER_REMOTE
	echo $$BROWSERS
	# -------
	TEST_STRIDER=1 ./node_modules/mocha/bin/mocha -R spec test/runner.js

test-client-sauce:
	./node_modules/mocha-selenium/bin/mocha-selenium.js -c test/client/selenium.json -p -e sauce test/client/dashboard.js test/client/projects.js

# ====== LOCAL:

test-local:
	# You need to run chromedriver for this to work. If you don't have it,
	# you can get it w/ npm install -g chromedriver
	# Then `chromedriver  --url-base=/wd/hub`
	$(which chromedriver)
	WEBDRIVER_REMOTE='{"hostname":"localhost","port":9515}' BROWSERS='[{"version":"","browserName":"chrome","platform":"Linux"}]' ./node_modules/mocha/bin/mocha -R spec test/runner.js

start-chromedriver:
	chromedriver --url-base=/wd/hub

test-client-local:
	./node_modules/.bin/mocha test/client/


test-syntax: lint

tolint := *.js *.json lib routes public/javascripts/pages public/javascripts/modules

lint:
	@./node_modules/.bin/jshint --verbose $(tolint)

strider_sub := strider-env strider-simple-worker strider-python strider-sauce strider-custom

link:
	npm link $(strider_sub)

unlink:
	npm install $(strider_sub)

authors-list:
	git shortlog -e -n -s $$commit | awk '{ args[NR] = $$0; sum += $$0 } END { for (i = 1; i <= NR; ++i) { printf "%-60s %2.1f%%\n", args[i], 100 * args[i] / sum } }' > AUTHORS


release: test build authors-list
	npm version minor




.PHONY: test lint watch build less start-chromedriver
