import Foundation

public struct SubtitleTimeline: Sendable {
    public let document: SubtitleDocument
    private let cues: [SubtitleCue]

    public init(document: SubtitleDocument) {
        self.document = document
        self.cues = document.cues.sorted { lhs, rhs in
            if lhs.startTime == rhs.startTime {
                lhs.endTime < rhs.endTime
            } else {
                lhs.startTime < rhs.startTime
            }
        }
    }

    public func activeCues(at mediaTime: TimeInterval, offset: TimeInterval = 0) -> [SubtitleCue] {
        let effectiveTime = max(0, mediaTime + offset)
        return cues.filter { cue in
            cue.startTime <= effectiveTime && effectiveTime < cue.endTime
        }
    }

    public func nextCue(after mediaTime: TimeInterval, offset: TimeInterval = 0) -> SubtitleCue? {
        let effectiveTime = max(0, mediaTime + offset)
        return cues.first { cue in
            cue.startTime > effectiveTime
        }
    }
}
