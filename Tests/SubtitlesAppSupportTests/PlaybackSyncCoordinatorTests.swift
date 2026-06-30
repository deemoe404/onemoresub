import XCTest
@testable import SubtitlesAppSupport

final class PlaybackSyncCoordinatorTests: XCTestCase {
    func testAppleTVSnapshotOverridesManualClock() {
        let observedAt = Date(timeIntervalSince1970: 100)
        let coordinator = PlaybackSyncCoordinator(
            manualTimeProvider: { 3 },
            manualIsPlayingProvider: { false },
            dateProvider: { observedAt }
        )

        coordinator.calibrate(with: AppleTVPlaybackSnapshot(
            state: .playing,
            position: 12,
            duration: 100,
            observedAt: observedAt
        ))

        let state = coordinator.renderState(offset: 0.5)

        XCTAssertEqual(state.mediaTime, 12)
        XCTAssertEqual(state.effectiveTime, 12.5)
        XCTAssertTrue(state.isPlaying)
        XCTAssertEqual(state.sourceLabel, "TV calibrated")
    }

    func testPausedAppleTVSnapshotKeepsPositionButMarksNotPlaying() {
        let observedAt = Date(timeIntervalSince1970: 100)
        let coordinator = PlaybackSyncCoordinator(
            manualTimeProvider: { 3 },
            manualIsPlayingProvider: { true },
            dateProvider: { observedAt.addingTimeInterval(10) }
        )

        coordinator.calibrate(with: AppleTVPlaybackSnapshot(
            state: .paused,
            position: 40,
            duration: 100,
            observedAt: observedAt
        ))

        let state = coordinator.renderState(offset: -1)

        XCTAssertEqual(state.mediaTime, 40)
        XCTAssertEqual(state.effectiveTime, 39)
        XCTAssertFalse(state.isPlaying)
        XCTAssertEqual(state.sourceLabel, "TV calibrated")
    }

    func testPlayingAppleTVSnapshotAdvancesFromObservationTime() {
        let observedAt = Date(timeIntervalSince1970: 100)
        let coordinator = PlaybackSyncCoordinator(
            manualTimeProvider: { 0 },
            manualIsPlayingProvider: { false },
            dateProvider: { observedAt.addingTimeInterval(2.5) }
        )

        coordinator.calibrate(with: AppleTVPlaybackSnapshot(
            state: .playing,
            position: 10,
            duration: 20,
            observedAt: observedAt
        ))

        let state = coordinator.renderState(offset: 0)

        XCTAssertEqual(state.mediaTime, 12.5)
        XCTAssertEqual(state.effectiveTime, 12.5)
    }

    func testUsesManualClockBeforeCalibration() {
        let coordinator = PlaybackSyncCoordinator(
            manualTimeProvider: { 9 },
            manualIsPlayingProvider: { true }
        )

        let state = coordinator.renderState(offset: 0.25)

        XCTAssertEqual(state.mediaTime, 9)
        XCTAssertEqual(state.effectiveTime, 9.25)
        XCTAssertTrue(state.isPlaying)
        XCTAssertEqual(state.sourceLabel, "Manual")
    }

    func testManualClockCanBePausedBeforeCalibration() {
        let coordinator = PlaybackSyncCoordinator(
            manualTimeProvider: { 5 },
            manualIsPlayingProvider: { false }
        )

        let state = coordinator.renderState(offset: 2)

        XCTAssertEqual(state.mediaTime, 5)
        XCTAssertEqual(state.effectiveTime, 7)
        XCTAssertFalse(state.isPlaying)
        XCTAssertEqual(state.sourceLabel, "Manual")
    }

    func testCalibrationSnapshotCarriesAppleTVSyncWhenPollingFails() {
        let observedAt = Date(timeIntervalSince1970: 100)
        let coordinator = PlaybackSyncCoordinator(
            manualTimeProvider: { 1 },
            manualIsPlayingProvider: { false },
            dateProvider: { observedAt.addingTimeInterval(4) }
        )

        coordinator.calibrate(with: AppleTVPlaybackSnapshot(
            state: .playing,
            position: 20,
            duration: 40,
            observedAt: observedAt
        ))

        let state = coordinator.renderState(offset: 0.5)

        XCTAssertEqual(state.mediaTime, 24)
        XCTAssertEqual(state.effectiveTime, 24.5)
        XCTAssertTrue(state.isPlaying)
        XCTAssertEqual(state.sourceLabel, "TV calibrated")
    }
}
