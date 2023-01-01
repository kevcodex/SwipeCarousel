// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwipeCarousel",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SwipeCarousel",
            targets: ["SwipeCarousel"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwipeCarousel",
            dependencies: []),
        .testTarget(
            name: "SwipeCarouselTests",
            dependencies: ["SwipeCarousel"]),
    ]
)
