import XCTest
@testable import SubtitleCore

final class SubtitlePlayerClockTests: XCTestCase {
    func testPlayPauseResumeAndReset() {
        let manualTime = ManualTime(now: 100)
        let clock = SubtitlePlayerClock(timeProvider: { manualTime.now })

        XCTAssertFalse(clock.isPlaying)
        XCTAssertEqual(clock.currentMediaTime(), 0, accuracy: 0.001)

        clock.play()
        manualTime.now = 102.25
        XCTAssertTrue(clock.isPlaying)
        XCTAssertEqual(clock.currentMediaTime(), 2.25, accuracy: 0.001)

        clock.pause()
        manualTime.now = 110
        XCTAssertFalse(clock.isPlaying)
        XCTAssertEqual(clock.currentMediaTime(), 2.25, accuracy: 0.001)

        clock.play()
        manualTime.now = 111
        XCTAssertEqual(clock.currentMediaTime(), 3.25, accuracy: 0.001)

        clock.reset()
        XCTAssertTrue(clock.isPlaying)
        XCTAssertEqual(clock.currentMediaTime(), 0, accuracy: 0.001)
    }

    func testOffsetAdjustment() {
        let clock = SubtitlePlayerClock(offset: 0.25)

        clock.adjustOffset(by: -0.5)
        XCTAssertEqual(clock.offset, -0.25, accuracy: 0.001)

        clock.setOffset(1.0)
        XCTAssertEqual(clock.offset, 1.0, accuracy: 0.001)
    }
}

final class ManualTime: @unchecked Sendable {
    var now: TimeInterval

    init(now: TimeInterval) {
        self.now = now
    }
}
