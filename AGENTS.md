# Gel: instructions for coding agents

Gel is a native macOS 15+ app built with Swift, SwiftUI and AppKit. Keep the app native; JavaScript and TypeScript examples below describe style for JS/TS tooling, not a new app stack or dependency.

## Start here

- Read `docs/project/role.md` for privacy invariants and `docs/project/conventions.md` for commands and existing code conventions before changing code.
- Follow the spec-first workflow in `CLAUDE.md`. For feature work, find the brief through `docs/README.md` and read its role, context, spec, interfaces/design and tasks. Get the user's agreement before implementing behaviour outside the agreed spec.
- Apply these guidelines to new or edited code. Keep changes focused on the requested task; leave unrelated code and other contributors' edits intact.

## Git and Conventional Commits

- Create a commit only when the user asks. Inspect `git status` and the diff first; stage explicit paths or hunks belonging to the task. Leave unrelated changes unstaged.
- Keep each commit focused on one coherent change. Separate a behaviour change from unrelated formatting or refactoring.
- Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/): `type(scope): summary`. The scope is optional; use a Gel feature or target such as `launcher`, `indexing`, `query`, `redaction`, `leak-guard`, `policy` or `voice` when useful.
- Choose the type that describes the change: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci` or `chore`. Reserve `style` for formatting that leaves behaviour unchanged, not visual UI changes.
- Write an imperative summary, such as “cancel stale answer streams”, with no trailing period. Aim for a subject of 72 characters or fewer. Add a body for the reason, trade-offs and verification when needed.
- Mark incompatible public API, CLI or configuration changes with `!` after the type/scope or a `BREAKING CHANGE:` footer explaining the migration.
- Before committing, review `git diff --cached` and run `git diff --cached --check`. Exclude secrets, real personal data and generated build artifacts. Amend commits or rewrite history only when the user asks.

```text
fix(launcher): cancel stale answer streams
feat(leak-guard): watch desktop chat apps
docs: clarify local model setup
```

## Immutable bindings and readable conditionals

- **Swift:** default to `let`; use `var` for values that change. Swift has no `const` keyword. Computed properties such as `body` and property-wrapper declarations such as `@State` and `@EnvironmentObject` require `var`.
- **JavaScript/TypeScript:** default to `const`; use `let` only when you reassign the binding. Avoid `var`. A `const` binding does not make an object or array immutable.
- Prefer `condition ? valueA : valueB` over `if`/`else` plus reassignment for two simple alternative values. Keep ternaries free of side effects and nesting.
- Use Swift `guard` or JS/TS early returns for validation and failure paths. Use `switch` for multiple enum cases. Keep `if`/`else` when branches perform distinct actions or build different SwiftUI view types; readability and correctness take priority over replacing every branch.

Swift example using Gel's provider type:

```swift
import GelCore

func providerTitle(_ provider: ProviderKind?) -> String {
    guard let provider else { return "Not answered yet" }
    let isLocal = provider == .local
    return isLocal ? "Local" : "Cloud"
}
```

Equivalent TypeScript style for tooling, if the task calls for it:

```typescript
const providerTitle = (provider: "local" | "cloud" | undefined): string => {
    if (provider === undefined) return "Not answered yet";
    const isLocal = provider === "local";
    return isLocal ? "Local" : "Cloud";
};
```

## Swift and SwiftUI in this project

- Respect the toolchain in `Gel/project.yml`: Swift 5 language mode and macOS 15 deployment target. Treat Swift 6 language/concurrency settings or an Observation migration as a separate, agreed task.
- Put engine logic in `Gel/GelCore/`, without SwiftUI imports. Put views, window/panel control and AppKit bridges in `Gel/Gel/`. Add detection patterns to pack JSON first when a pattern can express the behaviour.
- Prefer `struct` and `enum` for values and views. Use classes for identity, shared state or resource lifetime; mark them `final` when subclassing is unnecessary. Give view inputs immutable `let` properties.
- Follow the existing `AppState` pattern: `@MainActor`, `ObservableObject` and `@Published`. Use `@State private` for view-local values and `@Binding` for writable inputs. Use `@StateObject` when a view owns an observable object; use `@ObservedObject` or `@EnvironmentObject` for supplied objects.
- Keep `body` cheap and side-effect-free. Derive display values instead of storing duplicate state. Extract small named views/helpers; run database, OCR, indexing, detection and network work through services outside view construction.
- Update observable UI state on the main actor. Keep expensive synchronous work off it using a project-compatible worker/executor; adding `async` or wrapping work in `Task` alone does not guarantee that.
- Prefer structured concurrency for async operations. Use `.task`/`.task(id:)` for view-bound loading and honour cancellation. Track and cancel controller-owned tasks; a new launcher question must cancel its inner model stream and reject tokens from stale runs.
- Unwrap optionals with `guard`, `if let` or `??`; handle recoverable failures with `throws` and `do`/`catch`. Avoid force unwraps and `try!` unless you can document a guaranteed invariant.
- Use stable document/citation IDs in lists. Reuse `Theme`, `ProviderBadge`, `CitationChip`, `Card` and `EmptyStateView` instead of inventing parallel styling or components. Preserve loading, empty and error states, keyboard access, accessibility labels and Reduce Motion behaviour.
- Keep citation offsets in UTF-16 (`NSString`/`NSRange`) to match PDFKit. Preserve the privacy invariants in `docs/project/role.md` when changing prompts, redaction, logging or cloud routing.

App-target example: an immutable citation input, supplied app state and an existing UI component. The action handles navigation; the view does not perform engine work.

```swift
import SwiftUI
import GelCore

struct CitationAction: View {
    @EnvironmentObject private var state: AppState
    let citation: Citation

    var body: some View {
        CitationChip(citation: citation) {
            state.open(citation: citation)
        }
    }
}
```

## Verify before finishing

- Use the build, test and CLI commands in `docs/project/conventions.md`. Edit `Gel/project.yml` and regenerate with XcodeGen when project structure changes; keep generated `Gel.xcodeproj` files out of source edits.
- Add focused regression tests in `Gel/GelCoreTests/`, following the existing XCTest suite. Check engine behaviour with `gelcli` using a scratch `GEL_HOME`; check UI acceptance criteria in the app.
- For documentation-only changes, check referenced paths and examples; an app build is not required.
- Mark feature tasks complete only after observing their verification steps pass. In the handoff, name the changed files and checks you ran, including failures or checks you could not run.
