import Foundation

public struct SubtitleCue: Equatable, Sendable, Identifiable {
    public let id: String?
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let lines: [String]

    public var text: String {
        lines.joined(separator: "\n")
    }

    public init(
        id: String?,
        startTime: TimeInterval,
        endTime: TimeInterval,
        lines: [String]
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.lines = lines
    }
}

public enum SubtitleFormat: String, Equatable, Sendable {
    case srt
    case webVTT
}

public struct SubtitleDocument: Equatable, Sendable {
    public let sourceURL: URL?
    public let format: SubtitleFormat
    public let cues: [SubtitleCue]

    public init(sourceURL: URL?, format: SubtitleFormat, cues: [SubtitleCue]) {
        self.sourceURL = sourceURL
        self.format = format
        self.cues = cues
    }
}
