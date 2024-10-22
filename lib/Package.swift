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
        .library(name: "BluetoothNative", targets: ["BluetoothNative"]),
        .library(name: "JsMessage", targets: ["JsMessage"]),
        .library(name: "Helpers", targets: ["Helpers"]),
        .library(name: "WebView", targets: ["WebView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/Semaphore.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
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
                "Helpers",
                "JsMessage",
            ]
        ),
        .testTarget(
            name: "BluetoothClientTests",
            dependencies: ["BluetoothClient"]
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
            name: "JsMessage",
            dependencies: [
                "Helpers",
            ]
        ),

        .target(
            name: "Helpers",
            dependencies: [
                .product(name: "Semaphore", package: "Semaphore"),
            ]
        ),

        .target(
            name: "WebView",
            dependencies: [
                "Bluetooth",
                "BluetoothClient",
                "JsMessage",
            ],
            resources: [
                .copy("Resources/Generated/BluetoothPolyfill.js")
            ]
        ),
    ]
)
