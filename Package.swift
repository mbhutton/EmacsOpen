// swift-tools-version:5.9
import PackageDescription

let COMPILER_FLAGS = ["-diagnostic-style=llvm"]  // See Justfile for more '-Xswiftc' flags

let package = Package(
    name: "EmacsOpen",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "EmacsOpenLibrary", targets: ["EmacsOpenLibrary"]),
        .executable(name: "emacsopen", targets: ["EmacsOpenCLI"]),
    ],
    dependencies: [.package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")],
    targets: [
        .target(name: "EmacsOpenLibrary", dependencies: [], swiftSettings: [.unsafeFlags(COMPILER_FLAGS)]),
        .executableTarget(
            name: "EmacsOpenCLI",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser"), "EmacsOpenLibrary"],
            swiftSettings: [.unsafeFlags(COMPILER_FLAGS)]
        ),
        .executableTarget(
            name: "_EmacsOpenApp",  // Only used to help VS Code provide intellisense for the EmacsOpenApp swift files.
            dependencies: ["EmacsOpenLibrary"],
            path: "Sources/EmacsOpenApp",
            exclude: ["Info.plist", "EmacsOpen.entitlements"]
        ),
    ]
)
