// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "NetConfig",
    products: [
        .library(
            name: "NetConfig",
            targets: ["NetConfig"]),
        .executable(name: "linkstats", targets: ["linkstats"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "linkstats",
            dependencies: ["CNetlink", "NetConfigCHelpers", "NetConfig"]),
        .systemLibrary(
            name: "CNetlink",
            pkgConfig: "libnl-3.0",
            providers: [.apt(["libnl-3-dev"])]),
        .target(
            name: "NetConfigCHelpers",
            dependencies: []),
        .target(
            name: "NetConfig",
            dependencies: ["CNetlink", "NetConfigCHelpers"]),
        .testTarget(
            name: "NetConfigTests",
            dependencies: ["NetConfig"]),
    ]
)
