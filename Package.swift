// swift-tools-version: 5.9

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
            path: "Sources/LiveChatUI"
        )
    ]
)
