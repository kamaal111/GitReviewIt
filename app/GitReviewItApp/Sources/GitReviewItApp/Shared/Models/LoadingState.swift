import Foundation

/// Generic loading state wrapper for asynchronous operations
enum LoadingState<Value: Equatable>: Equatable {
    /// Initial state before any operation has been started
    case idle

    /// Operation is currently in progress
    case loading

    /// Operation completed successfully with a value
    case loaded(Value)

    /// Operation failed with an error
    case failed(APIError)

    // MARK: - Computed Properties

    /// Returns true if the state is currently loading
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    /// Returns the loaded value if available, otherwise nil
    var value: Value? {
        if case .loaded(let value) = self {
            return value
        }
        return nil
    }

    /// Returns the error if the operation failed, otherwise nil
    var error: APIError? {
        if case .failed(let error) = self {
            return error
        }
        return nil
    }

    /// Returns true if the state has a loaded value
    var hasValue: Bool {
        if case .loaded = self {
            return true
        }
        return false
    }

    /// Returns true if the state is in an error state
    var hasError: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    // MARK: - Equatable Conformance

    static func == (lhs: LoadingState<Value>, rhs: LoadingState<Value>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.loading, .loading):
            return true
        case (.loaded(let lhsValue), .loaded(let rhsValue)):
            return lhsValue == rhsValue
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
