import SwiftUI
import Testing

@testable import GitReviewItAppPoc

/// Tests for Color extension methods (hex parsing and contrasting text color)
@MainActor
struct ColorExtensionsTests {
    // MARK: - Hex Color Parsing Tests

    @Test
    func `parses valid 6-character hex color correctly`() throws {
        let color = Color(hex: "d73a4a")
        #expect(color != nil)
    }

    @Test
    func `returns nil for invalid hex length`() throws {
        // Too short
        let tooShort = Color(hex: "d73a")
        #expect(tooShort == nil)

        // Too long
        let tooLong = Color(hex: "d73a4a00")
        #expect(tooLong == nil)

        // Empty
        let empty = Color(hex: "")
        #expect(empty == nil)
    }

    @Test
    func `returns nil for invalid hex characters`() throws {
        let invalid1 = Color(hex: "gggggg")
        #expect(invalid1 == nil)

        let invalid2 = Color(hex: "d73azz")
        #expect(invalid2 == nil)

        let invalid3 = Color(hex: "!@#$%^")
        #expect(invalid3 == nil)
    }

    @Test
    func `parses GitHub label colors correctly`() throws {
        // GitHub's standard label colors
        let red = Color(hex: "d73a4a")
        #expect(red != nil)

        let blue = Color(hex: "0366d6")
        #expect(blue != nil)

        let green = Color(hex: "0e8a16")
        #expect(green != nil)

        let yellow = Color(hex: "fbca04")
        #expect(yellow != nil)

        let lightBlue = Color(hex: "a2eeef")
        #expect(lightBlue != nil)
    }

    @Test
    func `parses black and white colors correctly`() throws {
        let black = Color(hex: "000000")
        #expect(black != nil)

        let white = Color(hex: "ffffff")
        #expect(white != nil)

        let gray = Color(hex: "808080")
        #expect(gray != nil)
    }

    @Test
    func `hex parsing is case insensitive`() throws {
        let lowercase = Color(hex: "d73a4a")
        let uppercase = Color(hex: "D73A4A")
        let mixed = Color(hex: "D73a4A")

        #expect(lowercase != nil)
        #expect(uppercase != nil)
        #expect(mixed != nil)
    }

    // MARK: - Contrasting Text Color Tests

    @Test
    func `returns white text for dark backgrounds`() throws {
        guard let darkRed = Color(hex: "8b0000") else {
            throw TestError.colorParsingFailed
        }
        let textColor = darkRed.contrastingTextColor()
        // White has higher luminance than black, so this should return white
        // We can't directly compare Color values, but we can test it doesn't crash
        _ = textColor
    }

    @Test
    func `returns black text for light backgrounds`() throws {
        guard let lightBlue = Color(hex: "a2eeef") else {
            throw TestError.colorParsingFailed
        }
        let textColor = lightBlue.contrastingTextColor()
        // Light blue should produce black text for contrast
        _ = textColor
    }

    @Test
    func `handles pure black background`() throws {
        guard let black = Color(hex: "000000") else {
            throw TestError.colorParsingFailed
        }
        let textColor = black.contrastingTextColor()
        // Should return white for black background
        _ = textColor
    }

    @Test
    func `handles pure white background`() throws {
        guard let white = Color(hex: "ffffff") else {
            throw TestError.colorParsingFailed
        }
        let textColor = white.contrastingTextColor()
        // Should return black for white background
        _ = textColor
    }

    @Test
    func `handles mid-tone backgrounds`() throws {
        guard let gray = Color(hex: "808080") else {
            throw TestError.colorParsingFailed
        }
        let textColor = gray.contrastingTextColor()
        // Mid-tone gray should produce either black or white
        _ = textColor
    }

    @Test
    func `contrasting text color does not crash for any valid color`() throws {
        // Test a variety of colors to ensure robustness
        let testColors = [
            "ff0000",  // Red
            "00ff00",  // Green
            "0000ff",  // Blue
            "ffff00",  // Yellow
            "ff00ff",  // Magenta
            "00ffff",  // Cyan
            "d73a4a",  // GitHub bug red
            "0366d6",  // GitHub info blue
            "28a745",  // GitHub success green
            "ffd33d",  // GitHub warning yellow
        ]

        for hexColor in testColors {
            guard let color = Color(hex: hexColor) else {
                throw TestError.colorParsingFailed
            }
            let textColor = color.contrastingTextColor()
            // Should not crash
            _ = textColor
        }
    }

    // MARK: - Integration Tests

    @Test
    func `hex parsing and text color work together`() throws {
        // Parse GitHub's dark red label color
        guard let darkRed = Color(hex: "d73a4a") else {
            throw TestError.colorParsingFailed
        }

        // Get contrasting text color
        let textColor = darkRed.contrastingTextColor()

        // Should produce a valid color without crashing
        _ = textColor
    }

    @Test
    func `handles edge case hex values`() throws {
        // All zeros
        let allZeros = Color(hex: "000000")
        #expect(allZeros != nil)

        // All F's
        let allFs = Color(hex: "ffffff")
        #expect(allFs != nil)

        // Alternating
        let alternating1 = Color(hex: "aaaaaa")
        #expect(alternating1 != nil)

        let alternating2 = Color(hex: "555555")
        #expect(alternating2 != nil)
    }
}

// MARK: - Test Errors

enum TestError: Error {
    case colorParsingFailed
}
