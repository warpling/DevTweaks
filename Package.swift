// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TweakIt",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "TweakIt",
            targets: ["TweakIt"]
        ),
    ],
    targets: [
        .target(
            name: "TweakIt"
        ),
        .testTarget(
            name: "TweakItTests",
            dependencies: ["TweakIt"]
        ),
    ]
)
