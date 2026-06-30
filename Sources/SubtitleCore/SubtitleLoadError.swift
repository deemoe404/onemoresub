import Foundation

public enum SubtitleLoadError: Error, Equatable, LocalizedError, Sendable {
    case emptyFile
    case invalidEncoding
    case unsupportedFormat
    case malformed(String)

    public var errorDescription: String? {
        switch self {
        case .emptyFile:
            "Subtitle file is empty."
        case .invalidEncoding:
            "Subtitle file is not valid UTF-8 or UTF-16 text."
        case .unsupportedFormat:
            "Only SRT and WebVTT subtitles are supported."
        case let .malformed(reason):
            "Subtitle file is malformed: \(reason)"
        }
    }
}
