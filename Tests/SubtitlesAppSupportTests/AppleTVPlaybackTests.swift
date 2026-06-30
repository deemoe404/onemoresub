import XCTest
@testable import SubtitlesAppSupport

final class AppleTVPlaybackTests: XCTestCase {
    func testMapsPlaybackButtonDescriptionToActualState() {
        XCTAssertEqual(AppleTVPlaybackParser.stateFromPlaybackButtonDescription("Pause"), .playing)
        XCTAssertEqual(AppleTVPlaybackParser.stateFromPlaybackButtonDescription("Play"), .paused)
        XCTAssertNil(AppleTVPlaybackParser.stateFromPlaybackButtonDescription("AirPlay"))
    }

    func testPermissionErrorDescriptionIsAccessibilitySpecific() {
        XCTAssertEqual(
            AppleTVPlaybackError.accessibilityPermissionDenied.localizedDescription,
            "Accessibility permission for Subtitles is not granted."
        )
    }
}
