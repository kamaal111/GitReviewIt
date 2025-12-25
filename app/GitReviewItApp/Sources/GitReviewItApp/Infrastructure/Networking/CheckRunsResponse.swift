import Foundation

/// Response structure for decoding GitHub Check Runs API
///
/// Maps to the response from `GET /repos/{owner}/{repo}/commits/{ref}/check-runs`
/// See: https://docs.github.com/en/rest/checks/runs#list-check-runs-for-a-git-reference
///
/// **Usage**:
/// ```swift
/// let response = try JSONDecoder().decode(CheckRunsResponse.self, from: data)
/// let status = response.aggregatedStatus
/// ```
struct CheckRunsResponse: Decodable {
    let total_count: Int
    let check_runs: [CheckRun]

    /// Individual check run from GitHub Actions or other CI systems
    struct CheckRun: Decodable {
        /// Current status: "queued", "in_progress", "completed"
        let status: String

        /// Final conclusion (only present when status is "completed"):
        /// "success", "failure", "neutral", "cancelled", "timed_out", "action_required", "skipped"
        let conclusion: String?
    }

    /// Aggregates all check runs into a single status
    ///
    /// **Logic**:
    /// - Any failure/timeout/action_required → `.failing`
    /// - Any in_progress/queued → `.pending`
    /// - All success/neutral/skipped → `.passing`
    /// - Empty/no checks → `.unknown`
    ///
    /// - Returns: Aggregated PRCheckStatus
    var aggregatedStatus: PRCheckStatus {
        guard !check_runs.isEmpty else {
            return .unknown
        }

        var hasFailure = false
        var hasPending = false

        for run in check_runs {
            switch run.status {
            case "queued", "in_progress":
                hasPending = true
            case "completed":
                guard let conclusion = run.conclusion else {
                    continue
                }

                switch conclusion {
                case "failure", "timed_out", "action_required":
                    hasFailure = true
                case "success", "neutral", "skipped", "cancelled":
                    continue
                default:
                    continue
                }
            default:
                continue
            }
        }

        if hasFailure {
            return .failing
        }

        if hasPending {
            return .pending
        }

        return .passing
    }
}
