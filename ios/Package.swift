// swift-tools-version: 6.0
// Arena Protocol — Swift Package
// iOS 18+ target (forward compatible with iOS 26)
// Build with: Xcode 16+ or swift build (macOS)

import PackageDescription

let package = Package(
    name: "ArenaProtocol",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "ArenaProtocol",
            targets: ["ArenaProtocol"]
        )
    ],
    targets: [
        .target(
            name: "ArenaProtocol",
            path: "ArenaProtocol",
            sources: ["Models"]
        ),

        .testTarget(
            name: "ArenaProtocolTests",
            dependencies: ["ArenaProtocol"],
            path: "Tests/ArenaProtocolTests"
        )
    ]
)
