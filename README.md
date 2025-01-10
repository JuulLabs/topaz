# Topaz

Bluetooth Enabled Web Browser for iOS

## Development Tooling

Required tooling:

- Xcode
- Xcode Command Line Tools
- Npm

Optional tooling:

- swiftlint (soon to be replaced by `swift format`)
- xcbeautify (highly recommended when running tests from the command line)

### Building Javascript

Any changes to the `lib/Javascript` sources requires manually building and committing the final artifacts.
To compile the Typescript sources:

```sh
$ make js
```

This will output the compiled artifacts to `lib/Sources/WebView/Resources/Generated`. Submit these changes as part of the PR.

To compile the Javascript in a non-minified form for debugging:

```sh
$ make js-debug
```

To switch between the debug and production artifacts, use the `js-clean` target to force a re-build e.g.:

```sh
# Force re-build for testing:
$ make js-clean js-debug
# Force re-build for production:
$ make js-clean js
```

### CLI Build and Test

Installing onto a phone or simulator requires using Xcode. But for CI and local testing convenience there are makefiles for doing most tasks.

To build the entire project:

```sh
$ make build
```

The default build flavor is `Debug`. To use a different build configuration set `XCODE_CONFIG` e.g.:

```sh
$ make XCODE_CONFIG=Release build
```

To run tests for the entire project:

```sh
$ make test
```

To run tests for a specific SPM library module specify a target with the syntax `<module-name>Tests` e.g.:

```sh
$ make BluetoothEngineTests
```

To build all the modules in the SPM library using the bare swift tooling instead of `xcodebuild`:

```sh
$ make -C lib
```

To build a specific SPM library module set `TARGET` to the module name e.g.:

```sh
$ make -C lib TARGET=BluetoothEngine
```

To clean up and delete all build artifacts:

```sh
$ make clean
```

### Publishing To App Store

To trigger the `publish.yml` GitHub Action push a tag of the form `release/x.y.z` e.g.:

```sh
$ git tag -a release/1.2.3 -m "Verison 1.2.3 App Store Release"
$ git push origin release/1.2.3
```
