# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Swift 5.10, Swift 6.0 or NEEDS CLARIFICATION]  
**UI Framework**: [e.g., SwiftUI (Observation), SwiftUI + UIKit interop or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., None (stdlib only), Alamofire, SwiftData or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., SwiftData, CoreData, UserDefaults, Files, Keychain or N/A]  
**Testing**: [e.g., Swift Testing, Swift Testing + ViewInspector or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., iOS 18+, iOS 17+/macOS 15+, iOS/macOS/visionOS or NEEDS CLARIFICATION]  
**Architecture**: [e.g., Unidirectional data flow, TCA, MVVM or NEEDS CLARIFICATION]  
**Deployment Target**: [e.g., iOS 17.0, iOS 16.0, macOS 14.0 or NEEDS CLARIFICATION]  
**Performance Goals**: [domain-specific, e.g., 60 fps scrolling, <100ms load time, smooth animations or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., offline-first, <50MB app size, SwiftUI-only or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10 screens, 100k records, real-time sync or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Unidirectional Data Flow**
- [ ] Views are declarative and lightweight (no business logic)
- [ ] State is owned by explicit state containers
- [ ] State flows one direction: Intent → Container → View Update

**II. Protocol-Oriented Design**
- [ ] Cross-layer dependencies defined by protocols
- [ ] Services/repositories use protocol abstractions
- [ ] Test doubles are easily created via protocol conformance

**III. Separation of Concerns**
- [ ] Clear boundaries: UI / State / Domain / Infrastructure
- [ ] Domain models don't import SwiftUI/UIKit unnecessarily
- [ ] UI code doesn't perform I/O or side effects

**IV. Testability First**
- [ ] Core logic testable without SwiftUI
- [ ] No hard dependencies on singletons
- [ ] Side effects are injectable via protocols

**V. SwiftUI & Observation Standards**
- [ ] Views under 200 lines (target <150)
- [ ] State containers use `@Observable`
- [ ] Views use `@State` to own containers
- [ ] Navigation is state-driven and explicit

**VI. State Management**
- [ ] State containers expose intent-based methods
- [ ] No public mutable properties without justification
- [ ] Views send intent, not imperative mutations

**VII. Concurrency & Async**
- [ ] Swift Concurrency (`async/await`) used exclusively
- [ ] No new Combine usage (or justified)
- [ ] UI-facing state updates on main actor
- [ ] Task cancellation strategies defined

**VIII. Dependency Management**
- [ ] Minimize third-party dependencies
- [ ] Each dependency has documented justification
- [ ] Third-party types isolated by wrapper protocols

**IX. Code Style & Immutability**
- [ ] Prefer `let` and `struct` by default
- [ ] Descriptive naming over brevity
- [ ] Magic numbers/strings extracted as constants
- [ ] Intentional access control (`private` by default)

**X. Error Handling**
- [ ] Typed errors (enums conforming to Error)
- [ ] No force-try or force-unwrap in production
- [ ] Errors surfaced as explicit state
- [ ] User-facing error messages are actionable

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., Features/ReviewFeature). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: SwiftUI iOS/macOS application (feature-oriented)
GitReviewIt/
├── Features/
│   └── [FeatureName]/
│       ├── Views/
│       ├── State/
│       ├── Models/
│       └── Services/
├── Shared/
│   ├── Views/
│   ├── Models/
│   └── Extensions/
└── Infrastructure/
    ├── Networking/
    ├── Persistence/
    └── SystemAPIs/

GitReviewItTests/
├── UnitTests/
│   ├── StateTests/
│   ├── DomainTests/
│   └── ServiceTests/
└── IntegrationTests/

# [REMOVE IF UNUSED] Option 2: SwiftUI multiplatform with shared domain
Shared/
├── Domain/
│   ├── Models/
│   ├── UseCases/
│   └── Repositories/
└── Infrastructure/

iOS/
├── Features/
└── App/

macOS/
├── Features/
└── App/

Tests/
├── SharedTests/
├── iOSTests/
└── macOSTests/

# [REMOVE IF UNUSED] Option 3: SwiftUI + backend API
API/
└── [backend structure as appropriate]

iOS/
├── Features/
│   └── [FeatureName]/
│       ├── Views/
│       ├── State/
│       └── Models/
└── Infrastructure/
    └── APIClient/

iOSTests/
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above. For SwiftUI projects, justify feature-based vs layer-based organization.]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
