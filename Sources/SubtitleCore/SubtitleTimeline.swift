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

    public func nextBoundary(after mediaTime: TimeInterval, offset: TimeInterval = 0) -> TimeInterval? {
        let effectiveTime = max(0, mediaTime + offset)
        let nextEffectiveBoundary = cues.reduce(nil as TimeInterval?) { candidate, cue in
            let boundaries = [cue.startTime, cue.endTime].filter { $0 > effectiveTime }
            guard let cueBoundary = boundaries.min() else {
                return candidate
            }
            return min(candidate ?? cueBoundary, cueBoundary)
        }
        return nextEffectiveBoundary.map { max(0, $0 - offset) }
    }
}
