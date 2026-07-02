import SubtitlesAppCommon
import SubtitlesAppSupport

runSubtitlesApp(
    configuration: SubtitlesAppConfiguration(
        playbackClients: [
            QuickTimePlaybackClient()
        ],
        defaultPlaybackTargetID: ExternalPlaybackTarget.quickTime.id,
        updateController: NoopAppUpdateController(),
        accessibilityPermissionGranted: { false },
        showsAutomationSettings: true,
        showsAccessibilitySettings: false,
        showsUpdateMenu: false
    )
)
