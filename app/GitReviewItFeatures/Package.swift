// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GitReviewItFeatures",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitReviewItSelfUpdate", targets: ["GitReviewItSelfUpdate"]),
        .library(name: "GitReviewItAuthentication", targets: ["GitReviewItAuthentication"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", .upToNextMajor(from: "2.8.1")),
        .package(url: "https://github.com/Kamaalio/KamaalSwift", .upToNextMajor(from: "3.3.1")),
    ],
    targets: [
        .target(
            name: "GitReviewItSelfUpdate",
            dependencies: [
                .product(name: "KamaalLogger", package: "KamaalSwift"),
                "Sparkle",
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error),
                .strictMemorySafety(),
            ]
        ),
        .target(
            name: "GitReviewItAuthentication",
            dependencies: [
                .product(name: "KamaalLogger", package: "KamaalSwift"),
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error),
                .strictMemorySafety(),
            ]
        ),
    ]
)
