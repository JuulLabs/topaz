.PHONY: build clean debug

SCHEME ?= release

ifeq ($(SCHEME),debug)
	ROLLUP_SCHEME_OPTIONS :=
else
	ROLLUP_SCHEME_OPTIONS := --no-strict --plugin terser
endif

ROLLUP_OPTIONS := --format es --plugin typescript $(ROLLUP_SCHEME_OPTIONS)

OUTDIR := ../Sources/WebView/Resources/Generated
ENTRY_SOURCES := src/BluetoothPolyfill.ts
COMPILED_SOURCES := $(patsubst src/%.ts,$(OUTDIR)/%.js,$(ENTRY_SOURCES))
ALL_SOURCES := $(wildcard src/*.ts)

NPM_INSTALL := node_modules/.package-lock.json

build: $(OUTDIR) $(NPM_INSTALL) $(COMPILED_SOURCES)

debug:
	$(MAKE) SCHEME=debug build

clean:
	rm -f $(OUTDIR)/*.js

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OUTDIR)/%.js: src/%.ts $(ALL_SOURCES)
	npx rollup $(ROLLUP_OPTIONS) --file $@ $<

$(NPM_INSTALL): package-lock.json
	npm install
	touch $(NPM_INSTALL)

package-lock.json: package.json
	npm install
	touch package-lock.json
