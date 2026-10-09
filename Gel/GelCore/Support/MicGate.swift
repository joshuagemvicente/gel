import Foundation

/// Decides what a hold-to-talk press does for the current microphone access (voice spec, permission addendum).
/// Pure on purpose: the AVFoundation calls stay in the app target.
public enum MicGate {
    /// Raw values double as the DEBUG override values of `gel.debug.micAccess` (D-067).
    public enum Access: String, Equatable {
        case granted, undetermined, denied

        /// From an `AVAuthorizationStatus` raw value (0 not determined, 1 restricted, 2 denied, 3 authorized),
        /// so GelCore doesn't need AVFoundation. Restricted and unknown values count as denied.
        public init(authorizationStatus raw: Int) {
            switch raw {
            case 0: self = .undetermined
            case 3: self = .granted
            default: self = .denied
            }
        }
    }

    public enum Step: Equatable {
        case record
        case ask
        case explain(String)
    }

    public static let askingNotice = "Allow the microphone in the macOS prompt."
    public static let grantedNotice = "Microphone on. Hold right ⌥ again to talk."
    public static let deniedNotice = "Microphone access is off. Allow it in System Settings → Privacy → Microphone."

    public static func step(for access: Access) -> Step {
        switch access {
        case .granted: return .record
        case .undetermined: return .ask
        case .denied: return .explain(deniedNotice)
        }
    }

    /// The notice once the user answers the macOS prompt.
    public static func notice(afterAnswer granted: Bool) -> String {
        granted ? grantedNotice : deniedNotice
    }
}
