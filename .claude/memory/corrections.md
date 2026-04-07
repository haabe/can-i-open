# Corrections Log

## Format

Each correction entry follows this structure:

```
### [DATE] - [SHORT TITLE]
- **Scope**: [discovery | delivery | orchestration | quality]
- **Category**: [bias | security | engineering | process | communication]
- **Mistake**: What went wrong.
- **Correction**: What should have happened instead.
- **Prevention**: How to prevent this in the future (checklist item, gate, etc.).
- **Source**: Theory or principle that applies (e.g., "Torres - continuous discovery", "OWASP - input validation").
```

## Generalizable Corrections

_Corrections that apply broadly across projects and contexts._

### 2026-04-07 - SwiftUI Table cells lose EnvironmentObject
- **Scope**: delivery
- **Category**: engineering
- **Mistake**: Used `@EnvironmentObject` inside a view (`AppLabel`) rendered within SwiftUI `Table` column cells. During scrolling, Table reuses cells and the EnvironmentObject is not properly propagated, causing a crash (`_assertionFailure` in `EnvironmentObject.wrappedValue.getter`).
- **Correction**: Pass resolved values directly to child views used in Table cells instead of relying on EnvironmentObject. Pre-resolve data in the parent view that has access to the environment.
- **Prevention**: Never use `@EnvironmentObject` in views that will be rendered inside `Table` or `List` cells in macOS SwiftUI. Always pass concrete values as parameters.
- **Source**: Engineering best practice -- SwiftUI Table cell lifecycle.



### 2026-04-08 - AXIsProcessTrusted() unreliable for ad-hoc signed apps
- **Scope**: delivery
- **Category**: engineering
- **Mistake**: Used `AXIsProcessTrusted()` to check Accessibility permission. It returns false for ad-hoc signed apps even when permission is granted in System Settings, because the identity changes on each rebuild.
- **Correction**: Test Accessibility by making an actual AX API call (e.g., `AXUIElementCopyAttributeValue` on Finder). If it returns `.apiDisabled`, permission is missing. If it returns `.success`, permission works.
- **Prevention**: Never rely on `AXIsProcessTrusted()` for unsigned/ad-hoc apps. Always test with a real AX call. For release builds with stable code signing, `AXIsProcessTrusted()` works correctly.
- **Source**: macOS TCC (Transparency, Consent, and Control) identifies apps by code signing identity.

### 2026-04-08 - Accessibility permission resets on ad-hoc rebuild
- **Scope**: delivery
- **Category**: process
- **Mistake**: Each `swift build` produces a new binary, and even with `codesign --identifier`, macOS may invalidate the Accessibility permission grant when the binary hash changes.
- **Correction**: Use `codesign --force --sign - --identifier "com.canIOpen.app"` for stable identity. User must re-toggle permission in System Settings after rebuilds during development.
- **Prevention**: For release, use proper Developer ID signing. Document the re-toggle requirement for development contributors.
- **Source**: macOS code signing and TCC.

## Situational Corrections

_Corrections specific to a particular project, team, or context._

