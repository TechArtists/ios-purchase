// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

private let packageName = "TAPurchase"

let package = Package(
    name: packageName,
    platforms: [
        .iOS(.v15),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: packageName,
            targets: [packageName]),
    ],
    dependencies: [
        .package(url: "git@github.com:TechArtists/ios-analytics.git", .upToNextMajor(from: "0.9.0")),
        .package(url: "git@github.com:TechArtists/ios-debug-tools.git", .upToNextMajor(from: "0.9.0"))
    ],
    targets: [
        .target(
            name: packageName,
            dependencies: [
                .product(name: "TAAnalytics", package: "ios-analytics"),
                .product(name: "TADebugTools", package: "ios-debug-tools"),
            ]
        ),
    ]
)
