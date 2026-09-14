// swift-tools-version: 5.9

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
            path: "DevJournal",
            exclude: ["Info.plist"]
        )
    ]
)
