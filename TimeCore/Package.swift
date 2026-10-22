// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TimeCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TimeCore", targets: ["TimeCore"])
    ],
    targets: [
        .target(name: "TimeCore", path: "Sources/TimeCore"),
        .testTarget(name: "TimeCoreTests", dependencies: ["TimeCore"], path: "Tests/TimeCoreTests")
    ]
)
