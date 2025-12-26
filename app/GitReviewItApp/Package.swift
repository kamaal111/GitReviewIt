// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GitReviewItApp",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitReviewItApp", targets: ["GitReviewItApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", .upToNextMajor(from: "2.8.1"))
    ],
    targets: [
        .target(
            name: "GitReviewItApp",
            dependencies: [
                "Sparkle"
            ]
        ),
        .testTarget(
            name: "GitReviewItAppTests",
            dependencies: ["GitReviewItApp"]
        ),
    ]
)
