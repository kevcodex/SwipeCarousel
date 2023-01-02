// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeckView",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DeckView",
            targets: ["DeckView"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "DeckView",
            dependencies: []),
        .testTarget(
            name: "DeckViewTests",
            dependencies: ["DeckView"]),
    ]
)
