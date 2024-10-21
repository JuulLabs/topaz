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
        .library(name: "WebView", targets: ["WebView"]),
    ],
    dependencies: [
        // external dependencies go here
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
            dependencies: ["Bluetooth"]
        ),
        .testTarget(
            name: "BluetoothClientTests",
            dependencies: ["BluetoothClient"]
        ),

        .target(
            name: "WebView"
        ),
    ]
)
