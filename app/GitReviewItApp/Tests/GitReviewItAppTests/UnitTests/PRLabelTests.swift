import Foundation
import Testing

@testable import GitReviewItApp

/// Unit tests for PRLabel model validation and behavior
struct PRLabelTests {

    // MARK: - Initialization Tests

    @Test
    func `PRLabel initializes with valid name and color`() {
        let label = PRLabel(name: "bug", color: "d73a4a")

        #expect(label.name == "bug")
        #expect(label.color == "d73a4a")
        #expect(label.id == "bug")
    }

    @Test
    func `PRLabel uses name as identifier`() {
        let label1 = PRLabel(name: "feature", color: "a2eeef")
        let label2 = PRLabel(name: "bug", color: "d73a4a")

        #expect(label1.id == "feature")
        #expect(label2.id == "bug")
        #expect(label1.id != label2.id)
    }

    // MARK: - Validation Tests
    // Note: Precondition validation tests are omitted because preconditions cause
    // fatal errors that crash the test runner. In production, invalid inputs should
    // be prevented at the API boundary through proper input validation.

    @Test
    func `PRLabel accepts 6-character hex color`() {
        let label = PRLabel(name: "urgent", color: "ff0000")

        #expect(label.color == "ff0000")
    }

    // MARK: - Equatable Tests

    @Test
    func `PRLabel equality compares name and color`() {
        let label1 = PRLabel(name: "bug", color: "d73a4a")
        let label2 = PRLabel(name: "bug", color: "d73a4a")
        let label3 = PRLabel(name: "bug", color: "a2eeef")
        let label4 = PRLabel(name: "feature", color: "d73a4a")

        #expect(label1 == label2)
        #expect(label1 != label3)  // Different color
        #expect(label1 != label4)  // Different name
    }

    // MARK: - Decodable Tests

    @Test
    func `PRLabel decodes from valid JSON`() throws {
        let json = """
            {
                "name": "enhancement",
                "color": "a2eeef"
            }
            """

        let data = try #require(json.data(using: .utf8))
        let label = try JSONDecoder().decode(PRLabel.self, from: data)

        #expect(label.name == "enhancement")
        #expect(label.color == "a2eeef")
    }

    @Test
    func `PRLabel decoding fails for empty name`() throws {
        let json = """
            {
                "name": "",
                "color": "a2eeef"
            }
            """

        let data = try #require(json.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PRLabel.self, from: data)
        }
    }

    @Test
    func `PRLabel decoding fails for invalid color length`() throws {
        let json = """
            {
                "name": "bug",
                "color": "d73"
            }
            """

        let data = try #require(json.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PRLabel.self, from: data)
        }
    }

    @Test
    func `PRLabel decoding fails for missing name`() throws {
        let json = """
            {
                "color": "a2eeef"
            }
            """

        let data = try #require(json.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PRLabel.self, from: data)
        }
    }

    @Test
    func `PRLabel decoding fails for missing color`() throws {
        let json = """
            {
                "name": "bug"
            }
            """

        let data = try #require(json.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(PRLabel.self, from: data)
        }
    }

    // MARK: - Sendable Tests

    @Test
    func `PRLabel is Sendable and thread-safe`() {
        let label = PRLabel(name: "bug", color: "d73a4a")

        // This test verifies that PRLabel conforms to Sendable
        // If this compiles, it proves thread-safety guarantees
        let _: any Sendable = label

        #expect(label.name == "bug")
    }
}
