// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "applefm",
    platforms: [
        .macOS(.v26),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.0"),
    ],
    targets: [
        .target(
            name: "AppleFMCore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/AppleFMCore"
        ),
        .executableTarget(
            name: "applefm",
            dependencies: ["AppleFMCore"],
            path: "Sources/applefm"
        ),
        .testTarget(
            name: "AppleFMTests",
            dependencies: ["AppleFMCore"],
            path: "Tests/AppleFMTests"
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["AppleFMCore"],
            path: "Tests/IntegrationTests"
        ),
    ]
)
