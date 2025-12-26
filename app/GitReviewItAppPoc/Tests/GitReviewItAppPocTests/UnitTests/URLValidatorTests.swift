import Foundation
import Testing

@testable import GitReviewItAppPoc

@Suite("URL Validator Tests")
struct URLValidatorTests {

    @Test
    func `Valid HTTP URL`() {
        let url = "http://api.github.com"
        #expect(URLValidator.isValid(url))
    }

    @Test
    func `Valid HTTPS URL`() {
        let url = "https://api.github.com"
        #expect(URLValidator.isValid(url))
    }

    @Test
    func `Valid Enterprise URL with path`() {
        let url = "https://github.company.com/api/v3"
        #expect(URLValidator.isValid(url))
    }

    @Test
    func `Valid URL with surrounding whitespace`() {
        let url = "  https://api.github.com  "
        #expect(URLValidator.isValid(url))
    }

    @Test
    func `Invalid empty URL`() {
        #expect(!URLValidator.isValid(""))
    }

    @Test
    func `Invalid whitespace only URL`() {
        #expect(!URLValidator.isValid("   "))
    }

    @Test
    func `Invalid scheme (ftp)`() {
        let url = "ftp://api.github.com"
        #expect(!URLValidator.isValid(url))
    }

    @Test
    func `Invalid missing scheme`() {
        let url = "api.github.com"
        #expect(!URLValidator.isValid(url))
    }

    @Test
    func `Invalid missing host`() {
        let url = "https://"
        #expect(!URLValidator.isValid(url))
    }

    @Test
    func `Invalid malformed URL`() {
        let url = "https:// example.com"  // Space in host
        #expect(!URLValidator.isValid(url))
    }
}
