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
        .library(name: "Bluetooth", targets: ["Bluetooth"]),
        .library(name: "BluetoothAction", targets: ["BluetoothAction"]),
        .library(name: "BluetoothClient", targets: ["BluetoothClient"]),
        .library(name: "BluetoothEngine", targets: ["BluetoothEngine"]),
        .library(name: "BluetoothMessage", targets: ["BluetoothMessage"]),
        .library(name: "BluetoothNative", targets: ["BluetoothNative"]),
        .library(name: "Design", targets: ["Design"]),
        .library(name: "DevicePicker", targets: ["DevicePicker"]),
        .library(name: "Helpers", targets: ["Helpers"]),
        .library(name: "JsMessage", targets: ["JsMessage"]),
        .library(name: "Settings", targets: ["Settings"]),
        .library(name: "Tabs", targets: ["Tabs"]),
        .library(name: "UIHelpers", targets: ["UIHelpers"]),
        .library(name: "WebView", targets: ["WebView"]),
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
            dependencies: ["App"]
        ),

        .target(
            name: "Bluetooth",
            dependencies: [
                "Helpers",
            ]
        ),
        .testTarget(
            name: "BluetoothTests",
            dependencies: ["Bluetooth"]
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
            dependencies: ["BluetoothEngine"]
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
            dependencies: ["BluetoothNative"]
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
            dependencies: ["DevicePicker"]
        ),

        .target(
            name: "Helpers",
            dependencies: [
                .product(name: "Semaphore", package: "Semaphore"),
            ]
        ),
        .testTarget(
            name: "HelpersTests",
            dependencies: ["Helpers"]
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
