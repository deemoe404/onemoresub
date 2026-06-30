import AppKit
import Foundation

public final class AppleTVPlaybackClient {
    public static let tvBundleIdentifier = "com.apple.TV"

    private let bundleIdentifier: String
    private let scriptRunner: (String) -> Result<String, AppleTVPlaybackError>
    private let runningApplicationProvider: (String) -> [NSRunningApplication]

    public convenience init() {
        self.init(
            bundleIdentifier: Self.tvBundleIdentifier,
            scriptRunner: Self.runAppleScript(source:),
            runningApplicationProvider: NSRunningApplication.runningApplications(withBundleIdentifier:)
        )
    }

    init(
        bundleIdentifier: String,
        scriptRunner: @escaping (String) -> Result<String, AppleTVPlaybackError>,
        runningApplicationProvider: @escaping (String) -> [NSRunningApplication]
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.scriptRunner = scriptRunner
        self.runningApplicationProvider = runningApplicationProvider
    }

    public func snapshot() -> Result<AppleTVPlaybackSnapshot, AppleTVPlaybackError> {
        guard !runningApplicationProvider(bundleIdentifier).isEmpty else {
            return .failure(.notRunning)
        }

        return scriptRunner(Self.snapshotScript(bundleIdentifier: bundleIdentifier))
            .flatMap { rawValue in
                do {
                    return .success(try AppleTVPlaybackParser.parseAppleScriptResult(rawValue))
                } catch let error as AppleTVPlaybackError {
                    return .failure(error)
                } catch {
                    return .failure(.scriptError(error.localizedDescription))
                }
            }
    }

    public func requestAutomationPermission() -> Result<Void, AppleTVPlaybackError> {
        scriptRunner(Self.permissionProbeScript(bundleIdentifier: bundleIdentifier)).map { _ in () }
    }

    private static func snapshotScript(bundleIdentifier: String) -> String {
        """
        tell application id "\(bundleIdentifier)"
            set tvState to (player state as text)
            set tvPosition to "missing value"
            set tvDuration to "missing value"
            try
                set tvPosition to (player position as text)
            end try
            try
                set tvDuration to (duration of current track as text)
            end try
            return tvState & "|" & tvPosition & "|" & tvDuration
        end tell
        """
    }

    private static func permissionProbeScript(bundleIdentifier: String) -> String {
        """
        tell application id "\(bundleIdentifier)"
            return player state as text
        end tell
        """
    }

    private static func runAppleScript(source: String) -> Result<String, AppleTVPlaybackError> {
        guard let script = NSAppleScript(source: source) else {
            return .failure(.scriptError("Could not create AppleScript."))
        }

        var errorInfo: NSDictionary?
        let descriptor = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            return .failure(mapAppleScriptError(errorInfo))
        }

        return .success(descriptor.stringValue ?? "")
    }

    private static func mapAppleScriptError(_ errorInfo: NSDictionary) -> AppleTVPlaybackError {
        let number = (errorInfo[NSAppleScript.errorNumber] as? NSNumber)?.intValue
        let message = errorInfo[NSAppleScript.errorMessage] as? String
        let description = message ?? "Apple Events request failed."

        if number == -1743 || description.localizedCaseInsensitiveContains("not authorized") {
            return .permissionDenied
        }

        return .scriptError(description)
    }
}
