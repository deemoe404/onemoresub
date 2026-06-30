import Foundation

public final class PlaybackSyncCoordinator {
    public typealias ManualTimeProvider = () -> TimeInterval
    public typealias ManualIsPlayingProvider = () -> Bool
    public typealias DateProvider = () -> Date

    private let manualTimeProvider: ManualTimeProvider
    private let manualIsPlayingProvider: ManualIsPlayingProvider
    private let dateProvider: DateProvider
    private var calibratedSnapshot: AppleTVPlaybackSnapshot?

    public init(
        manualTimeProvider: @escaping ManualTimeProvider,
        manualIsPlayingProvider: @escaping ManualIsPlayingProvider,
        dateProvider: @escaping DateProvider = Date.init
    ) {
        self.manualTimeProvider = manualTimeProvider
        self.manualIsPlayingProvider = manualIsPlayingProvider
        self.dateProvider = dateProvider
    }

    public func renderState(offset: TimeInterval) -> PlaybackRenderState {
        if let calibratedSnapshot,
           let position = currentPosition(from: calibratedSnapshot) {
            return PlaybackRenderState(
                mediaTime: max(0, position),
                effectiveTime: max(0, position + offset),
                isPlaying: calibratedSnapshot.state.isActivelyAdvancing,
                sourceLabel: "TV calibrated"
            )
        }

        return manualRenderState(offset: offset, sourceLabel: "Manual")
    }

    public func calibrate(with snapshot: AppleTVPlaybackSnapshot) {
        calibratedSnapshot = snapshot
    }

    private func currentPosition(from snapshot: AppleTVPlaybackSnapshot) -> TimeInterval? {
        guard let position = snapshot.position else {
            return nil
        }
        guard snapshot.state == .playing else {
            return position
        }

        let elapsed = max(0, dateProvider().timeIntervalSince(snapshot.observedAt))
        let advancedPosition = position + elapsed
        if let duration = snapshot.duration {
            return min(advancedPosition, duration)
        }
        return advancedPosition
    }

    private func manualRenderState(offset: TimeInterval, sourceLabel: String) -> PlaybackRenderState {
        let mediaTime = max(0, manualTimeProvider())
        return PlaybackRenderState(
            mediaTime: mediaTime,
            effectiveTime: max(0, mediaTime + offset),
            isPlaying: manualIsPlayingProvider(),
            sourceLabel: sourceLabel
        )
    }
}
