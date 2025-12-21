// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GitReviewItApp",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "GitReviewItApp", targets: ["GitReviewItApp"]),
    ],
    targets: [
        .target(name: "GitReviewItApp"),
        .testTarget(name: "GitReviewItAppTests", dependencies: ["GitReviewItApp"]),
    ]
)
