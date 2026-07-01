// swift-tools-version: 6.0

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v5)
]

let distributionChannel = Context.environment["SUBTITLES_DISTRIBUTION_CHANNEL"]?.lowercased()
let isAppStoreOnlyManifest = distributionChannel == "appstore"

var products: [Product] = [
    .library(
        name: "SubtitleCore",
        targets: ["SubtitleCore"]
    )
]

if !isAppStoreOnlyManifest {
    products.append(
        .executable(
            name: "SubtitlesApp",
            targets: ["SubtitlesApp"]
        )
    )
}

products.append(
    .executable(
        name: "SubtitlesAppStore",
        targets: ["SubtitlesAppStore"]
    )
)
products.append(
    .executable(
        name: "SubtitleHarness",
        targets: ["SubtitleHarness"]
    )
)

var targets: [Target] = [
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
    .target(
        name: "SubtitlesAppCommon",
        dependencies: [
            "SubtitleCore",
            "SubtitlesAppSupport"
        ],
        swiftSettings: swiftSettings
    ),
    .executableTarget(
        name: "SubtitlesAppStore",
        dependencies: [
            "SubtitlesAppSupport",
            "SubtitlesAppCommon"
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
    )
]

if isAppStoreOnlyManifest {
    targets.append(
        .testTarget(
            name: "SubtitlesAppSupportTests",
            dependencies: ["SubtitlesAppSupport"],
            exclude: ["AppleTVPlaybackTests.swift"],
            swiftSettings: swiftSettings
        )
    )
} else {
    targets.append(contentsOf: [
        .binaryTarget(
            name: "Sparkle",
            path: "Vendor/Sparkle/Sparkle.xcframework"
        ),
        .target(
            name: "SubtitlesAppleTVSupport",
            dependencies: ["SubtitlesAppSupport"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "SubtitlesGitHubSupport",
            dependencies: [
                "SubtitlesAppCommon",
                "Sparkle"
            ],
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "SubtitlesApp",
            dependencies: [
                "SubtitlesAppSupport",
                "SubtitlesAppleTVSupport",
                "SubtitlesAppCommon",
                "SubtitlesGitHubSupport"
            ],
            swiftSettings: swiftSettings,
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../Frameworks"
                ])
            ]
        ),
        .testTarget(
            name: "SubtitlesAppSupportTests",
            dependencies: [
                "SubtitlesAppSupport",
                "SubtitlesAppleTVSupport"
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SubtitlesAppCommonTests",
            dependencies: [
                "SubtitlesAppCommon",
                "SubtitlesAppleTVSupport"
            ],
            swiftSettings: swiftSettings
        )
    ])
}

let package = Package(
    name: "Subtitles",
    platforms: [
        .macOS("26.0")
    ],
    products: products,
    targets: targets
)
