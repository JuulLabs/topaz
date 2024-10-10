// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
    ],
    products: [
        .library(name: "App", targets: ["App"]),
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
        .target(name: "WebView"),
        .testTarget(
            name: "AppTests",
            dependencies: ["App"]
        ),
    ]
)
