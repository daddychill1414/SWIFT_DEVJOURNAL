// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DevJournal",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "DevJournal",
            targets: ["DevJournal"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DevJournal",
            dependencies: [],
            path: "DevJournal"
        )
    ]
)

