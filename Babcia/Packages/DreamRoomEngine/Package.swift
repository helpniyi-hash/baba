// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DreamRoomEngine",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DreamRoomEngine",
            targets: ["DreamRoomEngine"]
        )
    ],
    targets: [
        .target(
            name: "DreamRoomEngine"
        ),
        .testTarget(
            name: "DreamRoomEngineTests",
            dependencies: ["DreamRoomEngine"]
        )
    ]
)
