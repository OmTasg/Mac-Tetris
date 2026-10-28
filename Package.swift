// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Stacker",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Stacker", targets: ["Stacker"])
    ],
    targets: [
        .executableTarget(
            name: "Stacker",
            path: "Sources/Stacker"
        )
    ]
)
