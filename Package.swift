// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DiffValueSubject",
    platforms: [
        .macOS("13.0"),
        .iOS("16.0"),
        .tvOS("16.0"),
        .watchOS("9.0")
    ],
    products: [
        .library(
            name: "DiffValueSubject",
            targets: ["DiffValueSubject"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DiffValueSubject",
            dependencies: []),

        .testTarget(
            name: "DiffValueSubjectTests",
            dependencies: ["DiffValueSubject"]),
    ],
    swiftLanguageModes: [.v6]
) 
