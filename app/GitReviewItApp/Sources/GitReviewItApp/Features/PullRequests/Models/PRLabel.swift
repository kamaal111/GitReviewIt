import Foundation
import OSLog

private let logger = Logger(subsystem: "com.gitreviewit.app", category: "PRLabel")

/// Represents a label/tag applied to a pull request
///
/// Labels provide categorical information about a PR (e.g., "bug", "feature", "urgent").
/// Each label has a name and a 6-character hex color code for visual representation.
///
/// **Invariants**:
/// - `name` must not be empty
/// - `color` must be a 6-character hex code (e.g., "d73a4a")
///
/// **Usage**:
/// ```swift
/// let label = PRLabel(name: "bug", color: "d73a4a")
/// ```
struct PRLabel: Identifiable, Equatable, Sendable {
    let name: String
    let color: String

    var id: String { name }

    /// Creates a new PR label with validation
    ///
    /// - Parameters:
    ///   - name: Label name (must not be empty)
    ///   - color: 6-character hex color code (e.g., "d73a4a")
    ///
    /// - Precondition: `name` must not be empty
    /// - Precondition: `color` must be exactly 6 characters
    init(name: String, color: String) {
        guard !name.isEmpty else {
            preconditionFailure("name must not be empty")
        }

        guard color.count == 6 else {
            preconditionFailure("color must be 6-character hex code")
        }

        self.name = name
        self.color = color
        logger.debug("Created PRLabel: \(name) with color: \(color)")
    }
}

// MARK: - Decodable Conformance

extension PRLabel: Decodable {
    enum CodingKeys: String, CodingKey {
        case name
        case color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let color = try container.decode(String.self, forKey: .color)

        guard !name.isEmpty else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Label name must not be empty"
                )
            )
        }

        guard color.count == 6 else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Label color must be 6-character hex code, got: \(color)"
                )
            )
        }

        self.name = name
        self.color = color
    }
}
