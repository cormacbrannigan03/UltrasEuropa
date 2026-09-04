// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "UltrasEuropaCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "UltrasEuropaCore",
            targets: ["UltrasEuropaCore"]
        )
    ],
    targets: [
        .target(
            name: "UltrasEuropaCore",
            dependencies: []
        ),
        .testTarget(
            name: "UltrasEuropaCoreTests",
            dependencies: ["UltrasEuropaCore"]
        ),
    ]
)
