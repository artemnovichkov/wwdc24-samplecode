/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Package that contains the RealityKit assets.
*/

// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RealityKit-Assets",
    platforms: [
        .visionOS(.v2),
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RealityKit-Assets",
            targets: ["RealityKit-Assets"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RealityKit-Assets",
            dependencies: [])
    ]
)
