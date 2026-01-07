// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DataLayer",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DataLayer",
            targets: ["DataLayer"]
        ),
    ],
    dependencies: [
        .package(path: "../Common"),
        .package(path: "../Core")
    ],
    targets: [
        .target(
            name: "DataLayer",
            dependencies: [
                .product(name: "Common", package: "Common"),
                .product(name: "Core", package: "Core")
            ]
        ),
        .testTarget(
            name: "DataLayerTests",
            dependencies: ["DataLayer"]
        ),
    ]
)
