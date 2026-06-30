// swift-tools-version: 6.0

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v5)
]

let package = Package(
    name: "Subtitles",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SubtitleCore",
            targets: ["SubtitleCore"]
        ),
        .executable(
            name: "SubtitlesApp",
            targets: ["SubtitlesApp"]
        ),
        .executable(
            name: "SubtitleHarness",
            targets: ["SubtitleHarness"]
        )
    ],
    targets: [
        .target(
            name: "SubtitleCore",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SubtitlesAppSupport",
            dependencies: ["SubtitleCore"],
            swiftSettings: swiftSettings,
            linkerSettings: [
                .linkedFramework("MediaAccessibility")
            ]
        ),
        .executableTarget(
            name: "SubtitlesApp",
            dependencies: [
                "SubtitleCore",
                "SubtitlesAppSupport"
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "SubtitleHarness",
            dependencies: ["SubtitleCore"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SubtitleCoreTests",
            dependencies: ["SubtitleCore"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SubtitlesAppSupportTests",
            dependencies: ["SubtitlesAppSupport"],
            swiftSettings: swiftSettings
        )
    ]
)
