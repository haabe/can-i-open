# Product Journal

Chronological log of product decisions, insights, and pivots.

## Format

```
### [DATE] - [TITLE]
- **Diamond**: [ID and phase]
- **Type**: [insight | decision | pivot | validation | invalidation]
- **Summary**: What happened and why it matters.
- **Evidence**: Links to supporting evidence.
- **Impact**: What changed as a result.
```

## Entries

### 2026-04-07 - Purpose validated, L2 Opportunity spawned
- **Diamond**: l0-purpose (complete) -> l2-opportunity-file-associations (discover)
- **Type**: validation
- **Summary**: Product purpose confirmed through founder interview + web research. The pain of macOS file type association hijacking is widespread (Apple Forums, MacRumors, GitHub). Existing tools are either dead (RCDefaultApp), abandoned (duti), barely maintained (SwiftDefaultApps), or CLI-only (utiluti). No modern GUI solution exists. LaunchServices API is stable and non-deprecated. Key technical risk: macOS 12+ confirmation dialogs for handler changes. L1 Strategy skipped (solo_hobby). L2 Opportunity spawned to scope features and architecture.
- **Evidence**: See purpose.yml, opportunities.yml, jobs-to-be-done.yml
- **Impact**: Clear go signal. Focus shifts to scoping MVP features and validating the confirmation dialog risk.

### 2026-04-07 - API feasibility spike: confirmed with dialog constraint
- **Diamond**: l2-opportunity-file-associations (discover)
- **Type**: validation
- **Summary**: Technical spike confirmed all LaunchServices APIs work. READ is blazing fast (~0.16ms/UTI). SET works but triggers a macOS confirmation dialog per call ("Do you want all documents to open with X or keep using Y?"). macOS groups related extensions in the dialog (.txt and .text together). API returns success immediately, change deferred until user clicks. App bundle scanning works (120 apps found, VS Code 65 types, VLC 102). Dynamic UTIs used for unregistered extensions (e.g. .rs). This means the app CAN do everything needed, but bulk SET operations require UX design around per-type dialogs.
- **Evidence**: spikes/api-feasibility/ -- ran on macOS 26.4 (Tahoe)
- **Impact**: Green light for building. UX design must account for one dialog per type change. The value proposition shifts toward: (1) discovering and understanding your current associations, (2) selecting what to change in bulk, (3) queuing changes so dialogs are predictable. The read/discover side is the stronger differentiator.

