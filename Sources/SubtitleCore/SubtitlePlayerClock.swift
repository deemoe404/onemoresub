import Foundation

public final class SubtitlePlayerClock: @unchecked Sendable {
    public typealias TimeProvider = @Sendable () -> TimeInterval

    private let timeProvider: TimeProvider
    private var anchorMediaTime: TimeInterval
    private var anchorSystemTime: TimeInterval

    public private(set) var isPlaying: Bool
    public private(set) var offset: TimeInterval

    public init(
        offset: TimeInterval = 0,
        timeProvider: @escaping TimeProvider = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.offset = offset
        self.timeProvider = timeProvider
        self.anchorMediaTime = 0
        self.anchorSystemTime = timeProvider()
        self.isPlaying = false
    }

    public func currentMediaTime() -> TimeInterval {
        guard isPlaying else {
            return anchorMediaTime
        }
        return max(0, anchorMediaTime + timeProvider() - anchorSystemTime)
    }

    public func play(resetToStart: Bool = false) {
        if resetToStart {
            anchorMediaTime = 0
        } else if isPlaying {
            return
        }
        anchorSystemTime = timeProvider()
        isPlaying = true
    }

    public func pause() {
        guard isPlaying else {
            return
        }
        anchorMediaTime = currentMediaTime()
        isPlaying = false
    }

    @discardableResult
    public func togglePlayPause() -> Bool {
        if isPlaying {
            pause()
        } else {
            play()
        }
        return isPlaying
    }

    public func reset() {
        anchorMediaTime = 0
        anchorSystemTime = timeProvider()
    }

    public func seek(to mediaTime: TimeInterval) {
        anchorMediaTime = max(0, mediaTime)
        anchorSystemTime = timeProvider()
    }

    public func setOffset(_ newOffset: TimeInterval) {
        offset = newOffset
    }

    public func adjustOffset(by delta: TimeInterval) {
        offset += delta
    }
}
