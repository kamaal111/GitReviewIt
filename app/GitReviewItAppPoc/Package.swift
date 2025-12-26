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
        .package(path: "../GitReviewItFeatures"),
    ],
    targets: [
        .target(
            name: "GitReviewItAppPoc",
            dependencies: [
                .product(name: "GitReviewItSelfUpdate", package: "GitReviewItFeatures"),
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
