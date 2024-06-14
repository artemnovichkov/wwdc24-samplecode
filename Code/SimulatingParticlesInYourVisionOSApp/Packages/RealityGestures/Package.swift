// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The package for handling tap and drag events on entities.
*/

import PackageDescription

let package = Package(
    name: "RealityGestures",
    platforms: [.visionOS(.v1)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "RealityGestures",
            targets: ["RealityGestures"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "RealityGestures",
            dependencies: [])
    ]
)
