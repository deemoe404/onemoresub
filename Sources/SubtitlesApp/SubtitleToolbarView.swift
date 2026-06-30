@preconcurrency import Cocoa
import Combine
import SwiftUI

protocol SubtitleToolbarViewDelegate: AnyObject {
    func subtitleToolbarViewDidEnter(_ view: SubtitleToolbarView)
    func subtitleToolbarViewDidExit(_ view: SubtitleToolbarView)
    func subtitleToolbarView(_ view: SubtitleToolbarView, didRequestScale factor: CGFloat)
    func subtitleToolbarView(_ view: SubtitleToolbarView, didAdjustOffsetBy delta: TimeInterval)
    func subtitleToolbarViewDidRequestCaptionSettings(_ view: SubtitleToolbarView)
    func subtitleToolbarViewDidRequestAppleTVCalibration(_ view: SubtitleToolbarView)
    func subtitleToolbarViewDidRequestPlayPause(_ view: SubtitleToolbarView)
    func subtitleToolbarViewDidRequestReset(_ view: SubtitleToolbarView)
    func subtitleToolbarViewDidRequestClose(_ view: SubtitleToolbarView)
}

final class SubtitleToolbarView: NSView {
    weak var delegate: SubtitleToolbarViewDelegate?

    private let model = SubtitleToolbarModel()
    private var hostingView: NSHostingView<SubtitleToolbarContentView>?
    private var trackingAreaRef: NSTrackingArea?

    override var intrinsicContentSize: NSSize {
        guard let hostingView else {
            return NSSize(width: 520, height: 38)
        }
        return hostingView.fittingSize
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        trackingAreaRef = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        delegate?.subtitleToolbarViewDidEnter(self)
    }

    override func mouseExited(with event: NSEvent) {
        delegate?.subtitleToolbarViewDidExit(self)
    }

    func setPlaybackState(isPlaying: Bool, time: TimeInterval, offset: TimeInterval, sourceLabel: String) {
        model.isPlaying = isPlaying
        model.playbackTime = time
        model.offset = offset
        model.sourceLabel = sourceLabel
        invalidateIntrinsicContentSize()
    }

    func setLoadedFileName(_ fileName: String?) {
        model.loadedFileName = fileName
        invalidateIntrinsicContentSize()
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = true
        autoresizingMask = [.width, .height]

        model.requestScale = { [weak self] factor in
            guard let self else {
                return
            }
            delegate?.subtitleToolbarView(self, didRequestScale: factor)
        }
        model.adjustOffset = { [weak self] delta in
            guard let self else {
                return
            }
            delegate?.subtitleToolbarView(self, didAdjustOffsetBy: delta)
        }
        model.requestCaptionSettings = { [weak self] in
            guard let self else {
                return
            }
            delegate?.subtitleToolbarViewDidRequestCaptionSettings(self)
        }
        model.requestAppleTVCalibration = { [weak self] in
            guard let self else {
                return
            }
            delegate?.subtitleToolbarViewDidRequestAppleTVCalibration(self)
        }
        model.requestPlayPause = { [weak self] in
            guard let self else {
                return
            }
            delegate?.subtitleToolbarViewDidRequestPlayPause(self)
        }
        model.requestReset = { [weak self] in
            guard let self else {
                return
            }
            delegate?.subtitleToolbarViewDidRequestReset(self)
        }
        model.requestClose = { [weak self] in
            guard let self else {
                return
            }
            delegate?.subtitleToolbarViewDidRequestClose(self)
        }

        let contentView = NSHostingView(rootView: SubtitleToolbarContentView(model: model))
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.setContentHuggingPriority(.required, for: .horizontal)
        contentView.setContentHuggingPriority(.required, for: .vertical)
        addSubview(contentView)
        hostingView = contentView

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

private final class SubtitleToolbarModel: ObservableObject {
    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0
    @Published var offset: TimeInterval = 0
    @Published var sourceLabel = "Manual"
    @Published var loadedFileName: String?

    var requestScale: ((CGFloat) -> Void)?
    var adjustOffset: ((TimeInterval) -> Void)?
    var requestCaptionSettings: (() -> Void)?
    var requestAppleTVCalibration: (() -> Void)?
    var requestPlayPause: (() -> Void)?
    var requestReset: (() -> Void)?
    var requestClose: (() -> Void)?

    var statusText: String {
        let file = loadedFileName.map { "  \($0)" } ?? ""
        return "\(sourceLabel)  \(formatTime(playbackTime))  Offset \(formatOffset(offset))\(file)"
    }

    var playPauseTitle: String {
        isPlaying ? "Pause" : "Play"
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let clamped = max(0, time)
        let minutes = Int(clamped) / 60
        let seconds = clamped.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%04.1f", minutes, seconds)
    }

    private func formatOffset(_ offset: TimeInterval) -> String {
        String(format: "%+.1fs", offset)
    }
}

private struct SubtitleToolbarContentView: View {
    @ObservedObject var model: SubtitleToolbarModel

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 10) {
                Text(model.statusText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: 360, alignment: .leading)
                    .layoutPriority(0)

                Divider()
                    .frame(height: 18)

                HStack(spacing: 6) {
                    toolbarButton("W-") { model.requestScale?(0.9) }
                    toolbarButton("W+") { model.requestScale?(1.1) }
                    toolbarButton("-0.5s") { model.adjustOffset?(-0.5) }
                    toolbarButton("+0.5s") { model.adjustOffset?(0.5) }
                    toolbarButton("Captions") { model.requestCaptionSettings?() }
                    toolbarButton("Calibrate TV") { model.requestAppleTVCalibration?() }
                    toolbarButton(model.playPauseTitle) { model.requestPlayPause?() }
                    toolbarButton("Reset") { model.requestReset?() }
                    toolbarButton("Close") { model.requestClose?() }
                }
                .layoutPriority(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassEffect(.regular.interactive(), in: Capsule())
        }
        .fixedSize(horizontal: true, vertical: true)
    }

    private func toolbarButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .buttonStyle(.glass)
            .controlSize(.small)
    }
}
