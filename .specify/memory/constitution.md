<!--
  Sync Impact Report (2025-12-20)
  ===============================
  Version: 0.0.0 → 1.0.0 (Initial constitution for greenfield SwiftUI project)
  
  Created Principles:
  - I. Unidirectional Data Flow
  - II. Protocol-Oriented Design
  - III. Separation of Concerns
  - IV. Testability First
  - V. SwiftUI & Observation Standards
  - VI. State Management
  - VII. Concurrency & Async
  - VIII. Dependency Management
  - IX. Code Style & Immutability
  - X. Error Handling
  
  Added Sections:
  - Project Evolution
  - Governance
  
  Templates requiring updates:
  - ✅ .specify/templates/plan-template.md (verified alignment)
  - ✅ .specify/templates/spec-template.md (verified alignment)
  - ✅ .specify/templates/tasks-template.md (verified alignment)
  
  Follow-up TODOs: None - all placeholders resolved.
-->

# GitReviewIt Constitution

## Core Principles

### I. Unidirectional Data Flow

Views MUST be declarative and lightweight. State MUST be owned by explicit state containers. Business logic MUST NEVER live in Views.

**Rationale**: Unidirectional data flow ensures predictable state changes, simplifies debugging, and enables reliable testing. By keeping Views free of business logic, we maintain a clear boundary between presentation and behavior, making the codebase easier to reason about and modify.

**Enforcement**:
- Views read state and send user intent only
- State changes flow in one direction: User Intent → State Container → View Update
- No direct state mutation from Views except via container-defined APIs
- Code reviews MUST reject business logic in View files

---

### II. Protocol-Oriented Design

Use protocols to define boundaries between layers. Enable dependency injection and mocking by default.

**Rationale**: Protocols provide abstraction boundaries that decouple implementation from interface. This enables testing with mocks, supports future platform extensions, and allows incremental refactoring without widespread changes. Swift's protocol-oriented design is a first-class language feature that should be leveraged for architectural clarity.

**Enforcement**:
- All cross-layer dependencies MUST be defined by protocols
- Concrete types MUST NOT be passed across architectural boundaries
- Services and repositories MUST conform to protocols
- Test doubles MUST be trivial to create via protocol conformance

---

### III. Separation of Concerns

Clear separation MUST exist between:
- **UI layer** (SwiftUI Views)
- **State & logic layer** (state containers)
- **Domain layer** (pure business logic and models)
- **Infrastructure layer** (networking, persistence, system APIs)

**Rationale**: Layered architecture prevents tangled dependencies, isolates change impact, and enables independent testing of each layer. Domain logic that doesn't depend on framework types can be reused across platforms and tested without SwiftUI or iOS SDK dependencies.

**Enforcement**:
- Domain models MUST NOT import SwiftUI or Foundation frameworks unless necessary
- Infrastructure code MUST NOT contain business rules
- UI code MUST NOT perform I/O or side effects directly
- Each layer MUST have explicit boundaries defined by protocols or clear module separation

---

### IV. Testability First

Core logic MUST be testable without SwiftUI. Avoid hard dependencies on singletons. Side effects MUST be injectable and replaceable.

**Rationale**: Testability is not a post-implementation concern—it guides design decisions from the start. Code that requires SwiftUI to test is fragile and slow. Singleton dependencies create hidden coupling and make tests unreliable. Injectable side effects enable controlled, fast, deterministic tests.

**Enforcement**:
- Business logic MUST NOT require SwiftUI or UIKit to test
- No global mutable state except framework-provided (e.g., UserDefaults when necessary)
- All I/O and side effects MUST be injected via protocols
- Test coverage MUST include domain and state management layers before UI integration

---

### V. SwiftUI & Observation Standards

SwiftUI Views MUST:
- Be small and composable (target <150 lines per View)
- Avoid business logic
- Avoid networking, persistence, or side effects

Use `@State` to own observable state containers in Views. Use `@Observable` for shared, mutable state models. Pass state explicitly through view hierarchies. Navigation MUST be state-driven and explicit.

**Rationale**: Small Views are easier to understand, test, and reuse. The Observation framework provides efficient reactivity without boilerplate. State-driven navigation makes navigation flows testable and prevents implicit dependencies on global router state.

**Enforcement**:
- Views exceeding 200 lines MUST be decomposed
- State containers MUST use `@Observable` macro
- Views MUST use `@State` to own container instances
- Navigation state MUST be explicit (no implicit NavigationStack magic)
- No `@EnvironmentObject` or `@ObservedObject` (use Observation instead)

---

### VI. State Management

**State containers**:
- Are reference types annotated with `@Observable`
- Own mutable state and orchestrate side effects
- Expose intent-based methods (not imperative mutations from Views)

**Views**:
- Read state
- Send user intent
- Never mutate state directly except via defined APIs

**Rationale**: Intent-based APIs communicate what the user wants to do, not how to do it. This decouples Views from implementation details and makes state changes auditable. State containers become the single source of truth, simplifying synchronization and debugging.

**Enforcement**:
- State container methods MUST be named as user intents (e.g., `submitReview()`, not `setReviewText()`)
- No public mutable properties on state containers unless explicitly justified
- Views MUST NOT perform multi-step state updates
- State containers MUST document invariants they maintain

---

### VII. Concurrency & Async

Use Swift Concurrency (`async/await`) exclusively. Avoid Combine unless strictly required for interop. All async side effects MUST be cancellable and testable. UI-facing state updates MUST occur on the main actor.

**Rationale**: Swift Concurrency provides structured, compiler-verified concurrency with clear cancellation semantics. Combine adds complexity and learning curve without corresponding benefit in modern Swift. Main actor isolation prevents race conditions and ensures UI consistency.

**Enforcement**:
- No new Combine usage without documented justification
- All async operations MUST use `async/await`
- State containers with UI-facing state MUST be `@MainActor` or update state on main actor
- Background work MUST NOT block the main thread
- All Task creations MUST have clear cancellation strategies

---

### VIII. Dependency Management

Prefer Swift Package Manager (SPM). Minimize third-party dependencies. Every dependency MUST have a clear justification.

**Rationale**: Dependencies are liabilities—they add compile time, increase app size, introduce security risks, and create lock-in. SPM is the native Swift solution with first-class Xcode integration. Each dependency must deliver value that justifies its cost.

**Enforcement**:
- New dependencies require documented justification (problem solved, alternatives considered, long-term maintenance risk)
- Wrapper protocols MUST isolate third-party types from domain logic
- Dependencies MUST support latest stable Swift and minimum deployment target
- No dependencies for functionality easily implemented in <100 lines

---

### IX. Code Style & Immutability

Prefer immutability by default. Favor value types unless identity or shared mutable state is required. Use clear, descriptive naming over brevity. Avoid magic numbers and hard-coded strings. Use access control intentionally.

**Rationale**: Immutable value types eliminate whole classes of bugs (race conditions, unintended mutations, reference cycles). Descriptive names reduce cognitive load. Access control documents intent and prevents misuse. These practices compound to create self-documenting, maintainable code.

**Enforcement**:
- Use `let` by default; `var` requires justification
- Use `struct` by default; `class` requires justification (identity, shared mutable state, reference semantics)
- No single-letter variable names except standard conventions (i, x, y in appropriate contexts)
- Magic numbers MUST be named constants
- Hard-coded strings MUST use localization or constants
- Use `private` and `fileprivate` by default; `internal` and `public` require intent documentation

---

### X. Error Handling

Errors MUST be explicit and typed. Failures MUST surface as explicit state. User-facing errors MUST be mapped to clear UI states.

**Rationale**: Silent failures and generic error types hide problems and frustrate users. Explicit error types document what can go wrong and force handling. Surfacing errors as state makes them testable and ensures consistent UI treatment.

**Enforcement**:
- Use typed errors (enums conforming to Error) instead of NSError or String
- No force-try or force-unwrap in production code
- Async operations MUST return Result or throw typed errors
- State containers MUST have explicit error state properties
- Error messages MUST be user-friendly and actionable (avoid technical jargon)

---

## Project Evolution

The architecture MUST support:
- **Feature modularization**: Code MUST be organized to enable future extraction into Swift Packages
- **Incremental refactoring**: Changes MUST be possible in small, safe steps
- **Reuse across Apple platforms**: Domain and state logic MUST NOT depend on iOS-specific APIs

**Principles**:
- Avoid premature abstraction, but NEVER block future extensibility
- Features SHOULD be organized by domain, not layer (e.g., `ReviewFeature/`, not `Models/`, `Views/`)
- Shared code MUST be extracted when used by 3+ features (not before)

---

## Governance

This constitution supersedes all other development practices and guides. All code reviews, architecture decisions, and design discussions MUST verify compliance with these principles.

**Amendment Process**:
1. Proposed changes MUST be documented with rationale and impact analysis
2. Constitution version MUST be incremented per semantic versioning:
   - **MAJOR**: Backward incompatible governance/principle removals or redefinitions
   - **MINOR**: New principle/section added or materially expanded guidance
   - **PATCH**: Clarifications, wording, typo fixes, non-semantic refinements
3. Amendments MUST include migration plan for existing code
4. All team members MUST be notified and acknowledge understanding

**Compliance Review**:
- All pull requests MUST pass constitution compliance check
- Violations MUST be justified in code review or rejected
- Complexity deviations MUST document why simpler approaches are insufficient
- Constitution check MUST occur at feature planning stage (before implementation)

**Guidance**:
For runtime development guidance and detailed workflows, refer to `.specify/templates/` for plan, spec, and task templates that operationalize these principles.

**Version**: 1.0.0 | **Ratified**: 2025-12-20 | **Last Amended**: 2025-12-20
