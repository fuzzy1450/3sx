// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Matchmaker",
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-nio-extras", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "matchmaker",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
            ]
        ),
    ]
)
