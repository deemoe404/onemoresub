import Foundation
import SubtitleCore

enum HarnessError: Error, LocalizedError {
    case usage
    case invalidTime(String)
    case invalidOffset(String)

    var errorDescription: String? {
        switch self {
        case .usage:
            return usageText
        case let .invalidTime(value):
            return "Invalid time: \(value)"
        case let .invalidOffset(value):
            return "Invalid offset: \(value)"
        }
    }
}

let usageText = """
Usage:
  SubtitleHarness parse <subtitle.srt|subtitle.vtt>
  SubtitleHarness at <subtitle.srt|subtitle.vtt> <seconds> [--offset <seconds>]
"""

func loadDocument(path: String) throws -> SubtitleDocument {
    let url = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)
    return try SubtitleParser.parse(data: data, sourceURL: url)
}

func parseOffset(from args: [String]) throws -> TimeInterval {
    guard let offsetIndex = args.firstIndex(of: "--offset") else {
        return 0
    }
    let valueIndex = args.index(after: offsetIndex)
    guard valueIndex < args.endIndex else {
        throw HarnessError.invalidOffset("")
    }
    guard let offset = TimeInterval(args[valueIndex]) else {
        throw HarnessError.invalidOffset(args[valueIndex])
    }
    return offset
}

func formatTime(_ time: TimeInterval) -> String {
    String(format: "%.3f", time)
}

func run() throws {
    let args = Array(CommandLine.arguments.dropFirst())
    guard let command = args.first else {
        throw HarnessError.usage
    }

    switch command {
    case "parse":
        guard args.count == 2 else {
            throw HarnessError.usage
        }
        let document = try loadDocument(path: args[1])
        print("format=\(document.format.rawValue)")
        print("cues=\(document.cues.count)")
        for cue in document.cues.prefix(5) {
            let cueID = cue.id.map { " id=\($0)" } ?? ""
            print("[\(formatTime(cue.startTime)) -> \(formatTime(cue.endTime))]\(cueID) \(cue.text.replacingOccurrences(of: "\n", with: " / "))")
        }

    case "at":
        guard args.count == 3 || args.count == 5 else {
            throw HarnessError.usage
        }
        guard let time = TimeInterval(args[2]) else {
            throw HarnessError.invalidTime(args[2])
        }
        let offset = try parseOffset(from: args)
        let document = try loadDocument(path: args[1])
        let timeline = SubtitleTimeline(document: document)
        let active = timeline.activeCues(at: time, offset: offset)
        print("time=\(formatTime(time))")
        print("offset=\(formatTime(offset))")
        print("active=\(active.count)")
        for cue in active {
            print(cue.text)
        }

    case "-h", "--help", "help":
        print(usageText)

    default:
        throw HarnessError.usage
    }
}

do {
    try run()
} catch {
    FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8))
    exit(2)
}
