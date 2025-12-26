import Foundation

/// Utility for validating URLs
enum URLValidator {
    /// Validates if a string is a valid URL for network requests
    /// - Parameter urlString: The string to validate
    /// - Returns: True if the string is a valid http/https URL with a host
    static func isValid(_ urlString: String) -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        guard let url = URL(string: trimmed) else { return false }

        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return false
        }

        guard let host = url.host, !host.isEmpty else {
            return false
        }

        return true
    }
}
