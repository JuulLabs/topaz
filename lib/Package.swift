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
        .library(name: "BluetoothClient", targets: ["BluetoothClient"]),
        .library(name: "BluetoothEngine", targets: ["BluetoothEngine"]),
        .library(name: "BluetoothNative", targets: ["BluetoothNative"]),
        .library(name: "Design", targets: ["Design"]),
        .library(name: "DevicePicker", targets: ["DevicePicker"]),
        .library(name: "Helpers", targets: ["Helpers"]),
        .library(name: "JsMessage", targets: ["JsMessage"]),
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
                "UIHelpers",
                "WebView",
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App"]
        ),

        .target(
            name: "Bluetooth"
        ),
        .testTarget(
            name: "BluetoothTests",
            dependencies: ["Bluetooth"]
        ),

        .target(
            name: "BluetoothClient",
            dependencies: [
                "Bluetooth",
                "DevicePicker",
                "Helpers",
                "JsMessage",
            ]
        ),
        .testTarget(
            name: "BluetoothClientTests",
            dependencies: ["BluetoothClient"]
        ),

        .target(
            name: "BluetoothEngine",
            dependencies: [
                "BluetoothClient",
            ]
        ),

        .target(
            name: "BluetoothNative",
            dependencies: [
                "BluetoothClient",
                "Helpers",
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

        .target(
            name: "JsMessage",
            dependencies: [
                "Helpers",
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
                "DevicePicker",
                "JsMessage",
            ],
            resources: [
                .copy("Resources/Generated/BluetoothPolyfill.js")
            ]
        ),
    ]
)
