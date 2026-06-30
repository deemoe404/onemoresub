import XCTest
@testable import SubtitleCore

final class SubtitleParserTests: XCTestCase {
    func testParsesSRTWithIdentifierAndMultilineText() throws {
        let text = """
        1
        00:00:01,000 --> 00:00:04,500
        Hello.
        World.

        2
        00:00:05,000 --> 00:00:06,000
        Next.
        """

        let document = try SubtitleParser.parse(data: Data(text.utf8), sourceURL: URL(fileURLWithPath: "sample.srt"))

        XCTAssertEqual(document.format, .srt)
        XCTAssertEqual(document.cues.count, 2)
        XCTAssertEqual(document.cues[0].id, "1")
        XCTAssertEqual(document.cues[0].startTime, 1.0, accuracy: 0.001)
        XCTAssertEqual(document.cues[0].endTime, 4.5, accuracy: 0.001)
        XCTAssertEqual(document.cues[0].lines, ["Hello.", "World."])
    }

    func testParsesWebVTTWithCueIdentifier() throws {
        let text = """
        WEBVTT

        intro
        00:00:00.500 --> 00:00:02.000
        Hello from VTT.

        00:00:03.000 --> 00:00:04.000
        Next cue.
        """

        let document = try SubtitleParser.parse(data: Data(text.utf8), sourceURL: URL(fileURLWithPath: "sample.vtt"))

        XCTAssertEqual(document.format, .webVTT)
        XCTAssertEqual(document.cues.count, 2)
        XCTAssertEqual(document.cues[0].id, "intro")
        XCTAssertEqual(document.cues[0].startTime, 0.5, accuracy: 0.001)
        XCTAssertEqual(document.cues[0].text, "Hello from VTT.")
    }

    func testHandlesUTF8ByteOrderMark() throws {
        let text = "\u{feff}1\n00:00:00,000 --> 00:00:01,000\nBOM handled.\n"

        let document = try SubtitleParser.parse(data: Data(text.utf8), sourceURL: URL(fileURLWithPath: "bom.srt"))

        XCTAssertEqual(document.cues.count, 1)
        XCTAssertEqual(document.cues[0].text, "BOM handled.")
    }

    func testThrowsForMalformedCueTiming() {
        let text = """
        1
        00:00:02,000 --> 00:00:01,000
        Bad.
        """

        XCTAssertThrowsError(try SubtitleParser.parse(data: Data(text.utf8), sourceURL: URL(fileURLWithPath: "bad.srt"))) { error in
            guard case SubtitleLoadError.malformed = error else {
                XCTFail("Expected malformed error, got \(error)")
                return
            }
        }
    }

    func testParsesMinuteSecondTimestamp() throws {
        let seconds = try XCTUnwrap(SubtitleParser.parseTimestamp("01:02,500"))
        XCTAssertEqual(seconds, 62.5, accuracy: 0.001)
    }
}
