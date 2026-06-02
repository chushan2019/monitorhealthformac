// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MonitorTool",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MonitorTool", targets: ["MonitorTool"])
    ],
    targets: [
        .executableTarget(
            name: "MonitorTool",
            dependencies: [],
            path: "Sources/MonitorTool",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("Cocoa"),
            ]
        )
    ]
)
