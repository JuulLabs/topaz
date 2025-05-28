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
                "Navigation",
                "Permissions",
                "SecurityList",
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
                "EventBus",
                "JsMessage",
                "SecurityList",
            ]
        ),
        .testTarget(
            name: "BluetoothActionTests",
            dependencies: ["BluetoothAction", "TestHelpers"]
        ),

        .target(
            name: "BluetoothClient",
            dependencies: [
                "Bluetooth",
                "EventBus",
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
                "EventBus",
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
                "EventBus",
                "JsMessage",
                "SecurityList",
            ]
        ),
        .testTarget(
            name: "BluetoothMessageTests",
            dependencies: ["BluetoothMessage", "TestHelpers"]
        ),

        .target(
            name: "BluetoothNative",
            dependencies: [
                "BluetoothClient",
                "EventBus",
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
            name: "EventBus",
            dependencies: [
                "Bluetooth",
                "JsMessage",
                "Helpers",
            ]
        ),
        .testTarget(
            name: "EventBusTests",
            dependencies: ["EventBus", "TestHelpers"]
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
            name: "Navigation",
            dependencies: [
                "Helpers",
            ]
        ),
        .testTarget(
            name: "NavigationTests",
            dependencies: ["Navigation", "TestHelpers"]
        ),

        .target(
            name: "Permissions",
            dependencies: [
                "Design",
                "UIHelpers",
            ]
        ),
        .testTarget(
            name: "PermissionsTests",
            dependencies: ["Permissions", "TestHelpers"]
        ),

        .target(
            name: "SecurityList",
            dependencies: []
        ),
        .testTarget(
            name: "SecurityListTests",
            dependencies: ["SecurityList", "TestHelpers"]
        ),

        .target(
            name: "Settings",
            dependencies: [
                "Design",
                "Permissions",
                "UIHelpers",
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
                "Navigation",
                "Permissions",
            ],
            resources: [
                .copy("Resources/Generated/BluetoothPolyfill.js")
            ]
        ),
    ]
)
