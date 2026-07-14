# Topaz

Bluetooth-enabled web browser for iOS/macOS. See `README.md` for the developer tooling overview and `make help` for the full target list.

## Cursor Cloud specific instructions

### Platform limitation (important)

This is a native **iOS/macOS app built with Xcode + SwiftUI + CoreBluetooth**. The primary developer workflows — `make build`, `make test`, `make run`, and the `*Tests` targets — all invoke `xcodebuild` against an iOS Simulator and therefore **only run on a macOS host with Xcode** (CI uses `macOS-15` runners; `.xcode-version` pins Xcode 26.2). None of these can build or run on the Linux Cloud VM. `swiftlint`/`swift format` (`make lint`) are also unavailable on Linux. Do not attempt `xcodebuild` here; there is no `xcrun`/Swift toolchain.

### What CAN be worked on in the Linux Cloud VM

Only the TypeScript Bluetooth polyfill under `lib/Javascript/` (Node/npm). It compiles `src/BluetoothPolyfill.ts` into the committed artifact `lib/Sources/WebView/Resources/Generated/BluetoothPolyfill.js` via rollup, driven by `make js` (production/minified) or `make js-debug` (non-minified). The compiled artifact is committed and consumed by the Swift `WebView` module, so it is NOT rebuilt during a normal app build — you only rebuild it when editing the `.ts` sources.

### Known-broken JS build (typescript v7)

`make js` / `make js-debug` currently **fail** in the repo's pinned dependency state. `package.json` pins `typescript: ^7.0.0`, which resolves to the new Go-based native compiler (`7.0.2`) that no longer exports the classic compiler API (`ts.ScriptTarget`, etc.). `@rollup/plugin-typescript` depends on that API, so rollup errors with `Cannot read properties of undefined (reading 'ES2015')`. This is a platform-independent dependency incompatibility (would also fail on macOS) and is NOT caught by CI — CI (`.github/workflows/ci.yml`) never runs `make js`. Rebuilding the polyfill requires either a compatible `typescript` version or a plugin that supports TS 7; treat that as a code change, not environment setup.

### Notes

- `make` at the repo root invokes `scripts/find_optimal_sim_uuid.sh`, which calls `xcrun` and prints `xcrun: not found` on Linux — harmless noise for the `js` targets.
- `lib/Javascript/node_modules` is gitignored. Dependencies are installed by the startup update script (`npm ci` in `lib/Javascript`). Use `npm ci` (not `npm install`) to avoid rewriting `package-lock.json`, which a newer npm otherwise churns (drops `libc` metadata).
