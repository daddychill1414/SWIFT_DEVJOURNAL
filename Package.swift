// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DevJournal",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "DevJournal",
            targets: ["DevJournal"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DevJournal",
            dependencies: [],
            path: "DevJournal"
        )
    ]
)
