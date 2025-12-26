import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.gitreviewit.app", category: "ColorExtensions")

extension Color {
    /// Creates a Color from a 6-character hex string (e.g., "d73a4a")
    ///
    /// - Parameter hex: A 6-character hex color code without the # prefix
    /// - Returns: A Color instance, or nil if the hex string is invalid
    ///
    /// - Note: The hex parameter should be exactly 6 characters. Invalid hex strings return nil.
    ///
    /// **Example**:
    /// ```swift
    /// let redColor = Color(hex: "d73a4a") // GitHub's red label color
    /// let blueColor = Color(hex: "0366d6") // GitHub's blue label color
    /// ```
    init?(hex: String) {
        guard hex.count == 6 else {
            logger.warning("Invalid hex color length: \(hex.count) (expected 6)")
            return nil
        }

        guard let intValue = Int(hex, radix: 16) else {
            logger.warning("Failed to parse hex color: \(hex)")
            return nil
        }

        let red = Double((intValue >> 16) & 0xFF) / 255.0
        let green = Double((intValue >> 8) & 0xFF) / 255.0
        let blue = Double(intValue & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)

        logger.debug("Parsed hex color: \(hex) -> RGB(\(red), \(green), \(blue))")
    }

    /// Determines the appropriate text color (black or white) for this background color
    /// based on relative luminance to ensure sufficient contrast for accessibility.
    ///
    /// Uses the WCAG relative luminance formula to calculate perceived brightness.
    /// For backgrounds with luminance > 0.5, returns black text; otherwise white text.
    ///
    /// - Returns: `.black` for light backgrounds, `.white` for dark backgrounds
    ///
    /// **Example**:
    /// ```swift
    /// let backgroundColor = Color(hex: "d73a4a")! // Red
    /// let textColor = backgroundColor.contrastingTextColor() // Returns .white
    /// ```
    func contrastingTextColor() -> Color {
        // Extract RGB components from the color
        // Note: This uses the NSColor/UIColor bridge for component extraction
        #if os(macOS)
            guard let nsColor = NSColor(self).usingColorSpace(.deviceRGB) else {
                logger.warning("Failed to convert Color to NSColor for luminance calculation")
                return .white  // Default to white on failure
            }

            let red = nsColor.redComponent
            let green = nsColor.greenComponent
            let blue = nsColor.blueComponent
        #else
            guard let uiColor = UIColor(self).cgColor.components, uiColor.count >= 3 else {
                logger.warning("Failed to extract RGB components for luminance calculation")
                return .white  // Default to white on failure
            }

            let red = uiColor[0]
            let green = uiColor[1]
            let blue = uiColor[2]
        #endif

        // Calculate relative luminance using WCAG formula
        // https://www.w3.org/TR/WCAG20/#relativeluminancedef
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue

        logger.debug("Calculated luminance: \(luminance) for RGB(\(red), \(green), \(blue))")

        // Use black text for light backgrounds (luminance > 0.5), white for dark backgrounds
        return luminance > 0.5 ? .black : .white
    }
}
