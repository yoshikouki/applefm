// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "applefm",
    platforms: [
        .macOS(.v26),
    ],
    targets: [
        .executableTarget(
            name: "applefm",
            path: "Sources"
        ),
    ]
)
