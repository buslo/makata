// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "makata",
    platforms: [.iOS(.v15), .macCatalyst(.v15)],
    products: [
        .library(name: "makata", targets: ["makataInteraction", "makataForm", "makataUserInterface"]),
    ],
    dependencies: [
        .package(url: "https://github.com/snapkit/snapkit.git", .upToNextMajor(from: "5.0.1")),
        .package(url: "https://github.com/nicklockwood/swiftformat", from: "0.50.4"),
    ],
    targets: [
        .target(name: "makataUserInterface",
                dependencies: [
                    "makataForm",
                    "makataInteraction",
                    .product(name: "SnapKit", package: "snapkit")
                ],
                path: "Sources/makata-user-interface"),
        .target(name: "makataForm",
                dependencies: [
                    "makataInteraction"
                ],
                path: "Sources/makata-form"),
        .target(name: "makataInteraction",
                path: "Sources/makata-interaction"),
    ]
)
