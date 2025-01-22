// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "App", targets: ["App"]),
        .library(name: "BluetoothNative", targets: ["BluetoothNative"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/Semaphore.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                "Design",
                "Settings",
                "Tabs",
                "UIHelpers",
                "WebView",
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App", "TestHelpers"]
        ),

        .target(
            name: "Bluetooth",
            dependencies: [
                "Helpers",
            ]
        ),
        .testTarget(
            name: "BluetoothTests",
            dependencies: ["Bluetooth", "TestHelpers"]
        ),

        .target(
            name: "BluetoothAction",
            dependencies: [
                "Bluetooth",
                "BluetoothClient",
                "BluetoothMessage",
                "DevicePicker",
                "JsMessage",
            ]
        ),

        .target(
            name: "BluetoothClient",
            dependencies: [
                "Bluetooth",
            ]
        ),
        .testTarget(
            name: "BluetoothClientTests",
            dependencies: ["BluetoothClient", "TestHelpers"]
        ),

        .target(
            name: "BluetoothEngine",
            dependencies: [
                "Bluetooth",
                "BluetoothAction",
                "BluetoothClient",
                "BluetoothMessage",
                "DevicePicker",
                "JsMessage",
            ]
        ),
        .testTarget(
            name: "BluetoothEngineTests",
            dependencies: ["BluetoothEngine", "TestHelpers"]
        ),

        .target(
            name: "BluetoothMessage",
            dependencies: [
                "Bluetooth",
                "BluetoothClient",
                "DevicePicker",
                "JsMessage",
            ]
        ),

        .target(
            name: "BluetoothNative",
            dependencies: [
                "BluetoothClient",
            ]
        ),
        .testTarget(
            name: "BluetoothNativeTests",
            dependencies: ["BluetoothNative", "TestHelpers"]
        ),

        .target(
            name: "Design",
            dependencies: [],
            resources: [.process("Resources")]
        ),

        .target(
            name: "DevicePicker",
            dependencies: [
                "Bluetooth",
                "Design",
                "Helpers",
            ]
        ),
        .testTarget(
            name: "DevicePickerTests",
            dependencies: ["DevicePicker", "TestHelpers"]
        ),

        .target(
            name: "Helpers",
            dependencies: [
                .product(name: "Semaphore", package: "Semaphore"),
            ]
        ),
        .testTarget(
            name: "HelpersTests",
            dependencies: ["Helpers", "TestHelpers"]
        ),

        .target(
            name: "JsMessage",
            dependencies: [
                "Helpers",
            ]
        ),

        .target(
            name: "Tabs",
            dependencies: [
                "Design",
                "UIHelpers",
            ]
        ),

        .target(
            name: "TestHelpers",
            dependencies: []
        ),

        .target(
            name: "Settings",
            dependencies: [
                "Design",
                "UIHelpers",
            ]
        ),

        .target(
            name: "UIHelpers",
            dependencies: [
                "Helpers",
            ]
        ),

        .target(
            name: "WebView",
            dependencies: [
                "Bluetooth",
                "BluetoothClient",
                "BluetoothEngine",
                "DevicePicker",
                "JsMessage",
            ],
            resources: [
                .copy("Resources/Generated/BluetoothPolyfill.js")
            ]
        ),
    ]
)
