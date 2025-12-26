// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GitReviewItAppPoc",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitReviewItAppPoc", targets: ["GitReviewItAppPoc"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", .upToNextMajor(from: "2.8.1"))
    ],
    targets: [
        .target(
            name: "GitReviewItAppPoc",
            dependencies: [
                "Sparkle"
            ]
        ),
        .testTarget(
            name: "GitReviewItAppPocTests",
            dependencies: ["GitReviewItAppPoc"],
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
