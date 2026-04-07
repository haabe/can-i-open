# API Feasibility Spike

Technical spike to validate macOS LaunchServices API behavior for file type association management.

## Questions to Answer

1. **Does `LSSetDefaultRoleHandlerForContentType` trigger a confirmation dialog for file UTIs?** (We know it does for URL schemes like `http`)
2. **Can we enumerate all registered UTIs and their current default handlers?**
3. **Can we read app bundles' `CFBundleDocumentTypes` to discover which apps claim which file types?**
4. **What does the API return when setting a handler -- can we detect if the user declined?**

## How to Run

```bash
cd spikes/api-feasibility
swift run
```

## Expected Observations

- If **no dialog appears** for file UTIs: bulk operations will be smooth. Green light for MVP.
- If **a dialog appears per-UTI**: need to design UX around batched confirmations. Still feasible but more complex.
- If **the API fails or is blocked**: need to investigate alternative approaches.
