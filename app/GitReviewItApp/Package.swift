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
        .package(path: "../GitReviewItFeatures"),
    ],
    targets: [
        .target(
            name: "GitReviewItApp",
            dependencies: [
                .product(name: "GitReviewItSelfUpdate", package: "GitReviewItFeatures"),
                .product(name: "GitReviewItAuthentication", package: "GitReviewItFeatures"),
            ]
        ),
        .testTarget(
            name: "GitReviewItAppTests",
            dependencies: ["GitReviewItApp"],
            swiftSettings: [
                .treatAllWarnings(as: .error),
                .strictMemorySafety(),
            ]
        ),
    ]
)
