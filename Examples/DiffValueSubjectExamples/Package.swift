// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DiffValueSubjectExamples",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .library(
            name: "DiffValueSubjectExamples",
            targets: ["DiffValueSubjectExamples"]
        )
    ],
    dependencies: [
        .package(path: "../../")
    ],
    targets: [
        .target(
            name: "DiffValueSubjectExamples",
            dependencies: [.product(name: "DiffValueSubject", package: "DynamicValueSubject")],
            path: "Sources"
        )
    ],
    swiftLanguageModes: [.v6]
)
