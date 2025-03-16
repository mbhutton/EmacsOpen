// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "EmacsOpen",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "EmacsOpenLibrary", targets: ["EmacsOpenLibrary"]),
        .executable(name: "emacsopen", targets: ["EmacsOpenCLI"]),
    ],
    dependencies: [.package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")],
    targets: [
        .target(name: "EmacsOpenLibrary", dependencies: []),
        .executableTarget(
            name: "EmacsOpenCLI",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"), "EmacsOpenLibrary"]
        ),
    ]
)
