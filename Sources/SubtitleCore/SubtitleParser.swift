import Foundation

public enum SubtitleParser {
    public static func parse(
        data: Data,
        sourceURL: URL? = nil,
        formatHint: SubtitleFormat? = nil
    ) throws -> SubtitleDocument {
        guard !data.isEmpty else {
            throw SubtitleLoadError.emptyFile
        }

        guard var text = decodeText(data) else {
            throw SubtitleLoadError.invalidEncoding
        }
        text = normalize(text)

        let format = try formatHint ?? detectFormat(text: text, sourceURL: sourceURL)
        let cues: [SubtitleCue]
        switch format {
        case .srt:
            cues = try parseSRT(text)
        case .webVTT:
            cues = try parseWebVTT(text)
        }

        guard !cues.isEmpty else {
            throw SubtitleLoadError.malformed("no subtitle cues found")
        }
        return SubtitleDocument(sourceURL: sourceURL, format: format, cues: cues)
    }

    private static func decodeText(_ data: Data) -> String? {
        if let utf8 = String(data: data, encoding: .utf8) {
            return utf8
        }
        if let utf16 = String(data: data, encoding: .utf16) {
            return utf16
        }
        if let utf16LE = String(data: data, encoding: .utf16LittleEndian) {
            return utf16LE
        }
        if let utf16BE = String(data: data, encoding: .utf16BigEndian) {
            return utf16BE
        }
        return nil
    }

    private static func normalize(_ text: String) -> String {
        var normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        if normalized.hasPrefix("\u{feff}") {
            normalized.removeFirst()
        }
        return normalized
    }

    private static func detectFormat(text: String, sourceURL: URL?) throws -> SubtitleFormat {
        if let sourceURL {
            switch sourceURL.pathExtension.lowercased() {
            case "srt":
                return .srt
            case "vtt", "webvtt":
                return .webVTT
            default:
                break
            }
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("WEBVTT") {
            return .webVTT
        }
        if text.contains("-->"), text.contains(",") {
            return .srt
        }
        if text.contains("-->"), text.contains(".") {
            return .webVTT
        }
        throw SubtitleLoadError.unsupportedFormat
    }

    private static func parseSRT(_ text: String) throws -> [SubtitleCue] {
        try cueBlocks(in: text).compactMap { block in
            try parseCueBlock(block, defaultIDFromFirstLine: true)
        }
    }

    private static func parseWebVTT(_ text: String) throws -> [SubtitleCue] {
        var body = text
        if body.hasPrefix("WEBVTT") {
            let lines = body.components(separatedBy: "\n")
            let bodyStart = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).isEmpty })
            if let bodyStart {
                body = lines.dropFirst(bodyStart + 1).joined(separator: "\n")
            } else {
                body = ""
            }
        }

        return try cueBlocks(in: body).compactMap { block in
            let first = block.first?.trimmingCharacters(in: .whitespaces) ?? ""
            if first == "NOTE" || first.hasPrefix("NOTE ") || first == "STYLE" || first == "REGION" {
                return nil
            }
            return try parseCueBlock(block, defaultIDFromFirstLine: false)
        }
    }

    private static func cueBlocks(in text: String) -> [[String]] {
        var blocks: [[String]] = []
        var current: [String] = []

        for rawLine in text.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .newlines)
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                if !current.isEmpty {
                    blocks.append(trimmedBlock(current))
                    current.removeAll(keepingCapacity: true)
                }
            } else {
                current.append(line)
            }
        }

        if !current.isEmpty {
            blocks.append(trimmedBlock(current))
        }
        return blocks.filter { !$0.isEmpty }
    }

    private static func trimmedBlock(_ lines: [String]) -> [String] {
        var result = lines
        while result.first?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            result.removeFirst()
        }
        while result.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            result.removeLast()
        }
        return result
    }

    private static func parseCueBlock(
        _ block: [String],
        defaultIDFromFirstLine: Bool
    ) throws -> SubtitleCue? {
        guard !block.isEmpty else {
            return nil
        }

        let timingIndex: Int
        let cueID: String?
        if block[0].contains("-->") {
            timingIndex = 0
            cueID = nil
        } else if block.count > 1, block[1].contains("-->") {
            timingIndex = 1
            cueID = block[0].trimmingCharacters(in: .whitespaces)
        } else if defaultIDFromFirstLine {
            throw SubtitleLoadError.malformed("missing timing line near '\(block[0])'")
        } else {
            return nil
        }

        let timingLine = block[timingIndex]
        let parts = timingLine.components(separatedBy: "-->")
        guard parts.count == 2 else {
            throw SubtitleLoadError.malformed("invalid timing line '\(timingLine)'")
        }

        guard let start = parseTimestamp(parts[0]) else {
            throw SubtitleLoadError.malformed("invalid start time '\(parts[0])'")
        }
        guard let end = parseTimestamp(parts[1]) else {
            throw SubtitleLoadError.malformed("invalid end time '\(parts[1])'")
        }
        guard end > start else {
            throw SubtitleLoadError.malformed("cue end must be after start")
        }

        let textLines = Array(block.dropFirst(timingIndex + 1))
        guard !textLines.isEmpty else {
            throw SubtitleLoadError.malformed("cue has no text")
        }

        return SubtitleCue(
            id: cueID,
            startTime: start,
            endTime: end,
            lines: textLines
        )
    }

    static func parseTimestamp(_ rawValue: String) -> TimeInterval? {
        let firstToken = rawValue
            .trimmingCharacters(in: .whitespaces)
            .split(whereSeparator: { $0 == " " || $0 == "\t" })
            .first
            .map(String.init) ?? ""
        let normalized = firstToken.replacingOccurrences(of: ",", with: ".")
        let components = normalized.split(separator: ":", omittingEmptySubsequences: false)
        guard components.count == 2 || components.count == 3 else {
            return nil
        }

        let hours: Double
        let minutes: Double
        let seconds: Double

        if components.count == 3 {
            guard let parsedHours = Double(components[0]),
                  let parsedMinutes = Double(components[1]),
                  let parsedSeconds = Double(components[2]) else {
                return nil
            }
            hours = parsedHours
            minutes = parsedMinutes
            seconds = parsedSeconds
        } else {
            guard let parsedMinutes = Double(components[0]),
                  let parsedSeconds = Double(components[1]) else {
                return nil
            }
            hours = 0
            minutes = parsedMinutes
            seconds = parsedSeconds
        }

        guard hours >= 0, minutes >= 0, seconds >= 0 else {
            return nil
        }
        return hours * 3600 + minutes * 60 + seconds
    }
}
