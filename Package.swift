// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Change Description:
// Author: Nipuna Lakruwan
// Date: 2026-11-02
// Previous Code: Basic Swift package without specified platform target or AppKit/SwiftUI minimum requirements.
// Modified Code: Added platforms requirement (.macOS(.v14)) to ensure modern macOS Sequoia/Sonoma UI features are enabled.
// How: Configured package platforms array with macOS 14 minimum target.

import PackageDescription

let package = Package(
    name: "AndroidMirror",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "AndroidMirror",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
        .testTarget(
            name: "AndroidMirrorTests",
            dependencies: ["AndroidMirror"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
    ]
)
