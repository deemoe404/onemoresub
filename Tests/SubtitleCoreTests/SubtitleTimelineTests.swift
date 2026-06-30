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

    func testNextBoundaryUsesCueStartsEndsAndGaps() {
        let document = SubtitleDocument(
            sourceURL: nil,
            format: .srt,
            cues: [
                SubtitleCue(id: "1", startTime: 5, endTime: 6, lines: ["First"]),
                SubtitleCue(id: "2", startTime: 8, endTime: 10, lines: ["Second"]),
                SubtitleCue(id: "3", startTime: 9, endTime: 12, lines: ["Overlap"])
            ]
        )
        let timeline = SubtitleTimeline(document: document)

        XCTAssertBoundary(timeline.nextBoundary(after: 0), equals: 5)
        XCTAssertBoundary(timeline.nextBoundary(after: 5.5), equals: 6)
        XCTAssertBoundary(timeline.nextBoundary(after: 6.1), equals: 8)
        XCTAssertBoundary(timeline.nextBoundary(after: 8.5), equals: 9)
        XCTAssertBoundary(timeline.nextBoundary(after: 9.5), equals: 10)
        XCTAssertBoundary(timeline.nextBoundary(after: 10.5), equals: 12)
        XCTAssertNil(timeline.nextBoundary(after: 12))
    }

    func testNextBoundaryUsesOffset() {
        let document = SubtitleDocument(
            sourceURL: nil,
            format: .srt,
            cues: [
                SubtitleCue(id: "1", startTime: 5, endTime: 6, lines: ["First"]),
                SubtitleCue(id: "2", startTime: 8, endTime: 9, lines: ["Second"])
            ]
        )
        let timeline = SubtitleTimeline(document: document)

        XCTAssertBoundary(timeline.nextBoundary(after: 3.5, offset: 2), equals: 4)
        XCTAssertBoundary(timeline.nextBoundary(after: 4.1, offset: 2), equals: 6)
        XCTAssertBoundary(timeline.nextBoundary(after: 8, offset: -3), equals: 9)
    }
}

private func XCTAssertBoundary(
    _ actual: TimeInterval?,
    equals expected: TimeInterval,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let actual else {
        XCTFail("Expected subtitle boundary \(expected)", file: file, line: line)
        return
    }
    XCTAssertEqual(actual, expected, accuracy: 0.001, file: file, line: line)
}
