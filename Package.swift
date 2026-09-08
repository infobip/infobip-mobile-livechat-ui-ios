// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "infobip-mobile-livechat-ui-ios",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "LiveChatUI",
            targets: ["LiveChatUI"]
        )
    ],
    targets: [
        .target(
            name: "LiveChatUI",
            path: "Sources/LiveChatUI",
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("InferSendableFromCaptures")
            ]
        ),
        .testTarget(
            name: "LiveChatUITests",
            dependencies: ["LiveChatUI"],
            path: "Tests/LiveChatUITests",
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
