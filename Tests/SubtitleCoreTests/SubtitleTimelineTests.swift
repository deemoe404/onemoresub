import XCTest
@testable import SubtitleCore

final class SubtitleTimelineTests: XCTestCase {
    func testActiveCuesUsePositiveOffsetAsEffectiveTimeAdvance() {
        let document = SubtitleDocument(
            sourceURL: nil,
            format: .srt,
            cues: [
                SubtitleCue(id: "1", startTime: 10, endTime: 12, lines: ["Active"]),
                SubtitleCue(id: "2", startTime: 20, endTime: 22, lines: ["Later"])
            ]
        )
        let timeline = SubtitleTimeline(document: document)

        XCTAssertTrue(timeline.activeCues(at: 9.6, offset: 0).isEmpty)
        XCTAssertEqual(timeline.activeCues(at: 9.6, offset: 0.5).map(\.text), ["Active"])
        XCTAssertTrue(timeline.activeCues(at: 12.0, offset: 0).isEmpty)
    }

    func testNextCueUsesOffset() {
        let document = SubtitleDocument(
            sourceURL: nil,
            format: .srt,
            cues: [
                SubtitleCue(id: "1", startTime: 5, endTime: 6, lines: ["First"]),
                SubtitleCue(id: "2", startTime: 8, endTime: 9, lines: ["Second"])
            ]
        )
        let timeline = SubtitleTimeline(document: document)

        XCTAssertEqual(timeline.nextCue(after: 4.0, offset: 0)?.text, "First")
        XCTAssertEqual(timeline.nextCue(after: 4.0, offset: 2.0)?.text, "Second")
    }
}
