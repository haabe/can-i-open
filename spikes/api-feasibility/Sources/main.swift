import Foundation
import CoreServices
import UniformTypeIdentifiers

// MARK: - API Feasibility Spike
// Tests macOS LaunchServices APIs for file type association management.
// Run from terminal: cd spikes/api-feasibility && swift run

print("=== macOS File Type Association API Feasibility Spike ===\n")
print("macOS version: \(ProcessInfo.processInfo.operatingSystemVersionString)\n")

// MARK: - Test 1: Query current default handlers for common UTIs

print("--- Test 1: Query Default Handlers ---\n")

let testUTIs: [(String, String)] = [
    ("public.plain-text", ".txt"),
    ("public.html", ".html"),
    ("public.json", ".json"),
    ("public.python-script", ".py"),
    ("public.shell-script", ".sh"),
    ("public.png", ".png"),
    ("public.jpeg", ".jpg"),
    ("com.adobe.pdf", ".pdf"),
    ("public.mp4", ".mp4"),
    ("public.swift-source", ".swift"),
    ("public.c-source", ".c"),
    ("public.xml", ".xml"),
    ("public.comma-separated-values-text", ".csv"),
    ("com.apple.property-list", ".plist"),
    ("public.yaml", ".yaml"),
]

for (uti, ext) in testUTIs {
    let cfUTI = uti as CFString

    // Get default handler (viewer role)
    if let handler = LSCopyDefaultRoleHandlerForContentType(cfUTI, LSRolesMask.viewer) {
        print("  \(ext.padding(toLength: 10, withPad: " ", startingAt: 0)) (\(uti))")
        print("    Default viewer: \(handler.takeRetainedValue())")
    }

    // Get default handler (editor role)
    if let handler = LSCopyDefaultRoleHandlerForContentType(cfUTI, LSRolesMask.editor) {
        print("    Default editor: \(handler.takeRetainedValue())")
    }

    // Get ALL handlers
    if let handlers = LSCopyAllRoleHandlersForContentType(cfUTI, LSRolesMask.all) {
        let apps = handlers.takeRetainedValue() as! [String]
        print("    All handlers (\(apps.count)): \(apps.prefix(5).joined(separator: ", "))\(apps.count > 5 ? "..." : "")")
    }
    print()
}

// MARK: - Test 2: Enumerate UTIs using UniformTypeIdentifiers framework

print("--- Test 2: UTType Framework ---\n")

if let txtType = UTType(filenameExtension: "txt") {
    print("  .txt -> UTType: \(txtType.identifier)")
    print("    Description: \(txtType.localizedDescription ?? "none")")
    print("    Conforms to: \(txtType.supertypes.map(\.identifier).joined(separator: ", "))")
}

if let mdType = UTType(filenameExtension: "md") {
    print("  .md  -> UTType: \(mdType.identifier)")
    print("    Description: \(mdType.localizedDescription ?? "none")")
}

if let rsType = UTType(filenameExtension: "rs") {
    print("  .rs  -> UTType: \(rsType.identifier)")
    print("    Description: \(rsType.localizedDescription ?? "none")")
} else {
    print("  .rs  -> UTType: not found (dynamic type)")
}

print()

// MARK: - Test 3: Set a default handler (THE KEY TEST)
// This tests whether a confirmation dialog appears for file UTIs.
// We pick a safe UTI (.txt) and set it to a known handler.

print("--- Test 3: Set Default Handler (Confirmation Dialog Test) ---\n")

// First, get the current default editor for .txt
let txtUTI = "public.plain-text" as CFString
var originalHandler: String? = nil

if let handler = LSCopyDefaultRoleHandlerForContentType(txtUTI, LSRolesMask.editor) {
    originalHandler = handler.takeRetainedValue() as String
    print("  Current .txt editor: \(originalHandler!)")
}

// Get all available editors for .txt
if let handlers = LSCopyAllRoleHandlersForContentType(txtUTI, LSRolesMask.editor) {
    let apps = handlers.takeRetainedValue() as! [String]
    print("  Available .txt editors: \(apps.joined(separator: ", "))")

    // Find an alternative editor to switch to (and back)
    if let alternative = apps.first(where: { $0 != originalHandler }) {
        print("\n  Attempting to set .txt editor to: \(alternative)")
        print("  >>> WATCH FOR A CONFIRMATION DIALOG <<<\n")

        let result = LSSetDefaultRoleHandlerForContentType(txtUTI, LSRolesMask.editor, alternative as CFString)
        print("  LSSetDefaultRoleHandlerForContentType returned: \(result) (0 = success)")

        // Check if it actually changed
        if let newHandler = LSCopyDefaultRoleHandlerForContentType(txtUTI, LSRolesMask.editor) {
            let newValue = newHandler.takeRetainedValue() as String
            print("  New .txt editor: \(newValue)")
            if newValue == alternative {
                print("  ✓ Change was applied (no dialog blocked it)")
            } else {
                print("  ✗ Change was NOT applied (dialog may have been declined, or API was blocked)")
            }
        }

        // Restore original
        if let original = originalHandler {
            print("\n  Restoring original handler: \(original)")
            let restoreResult = LSSetDefaultRoleHandlerForContentType(txtUTI, LSRolesMask.editor, original as CFString)
            print("  Restore returned: \(restoreResult) (0 = success)")

            if let restored = LSCopyDefaultRoleHandlerForContentType(txtUTI, LSRolesMask.editor) {
                print("  Confirmed .txt editor: \(restored.takeRetainedValue())")
            }
        }
    } else {
        print("  ⚠ Only one editor available for .txt -- cannot test switching.")
        print("    Install a second text editor to test this.")
    }
} else {
    print("  ⚠ Could not enumerate .txt editors")
}

print()

// MARK: - Test 4: Bulk operation simulation

print("--- Test 4: Bulk Operation Timing ---\n")

let bulkUTIs = ["public.plain-text", "public.html", "public.json", "public.xml",
                "public.comma-separated-values-text"]

print("  Querying default handlers for \(bulkUTIs.count) UTIs...")
let startTime = Date()

for uti in bulkUTIs {
    _ = LSCopyDefaultRoleHandlerForContentType(uti as CFString, LSRolesMask.editor)
    _ = LSCopyAllRoleHandlersForContentType(uti as CFString, LSRolesMask.all)
}

let elapsed = Date().timeIntervalSince(startTime) * 1000
print("  Completed in \(String(format: "%.1f", elapsed))ms")
print("  Projected time for 100 UTIs: \(String(format: "%.0f", elapsed / Double(bulkUTIs.count) * 100))ms")

print()

// MARK: - Test 5: Discover registered types from installed apps

print("--- Test 5: App Bundle Type Discovery ---\n")

let appDirs = ["/Applications", "/System/Applications"]
var totalApps = 0
var totalTypes = 0

for dir in appDirs {
    let fm = FileManager.default
    guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { continue }

    let apps = contents.filter { $0.hasSuffix(".app") }
    totalApps += apps.count

    for app in apps.prefix(5) {
        let plistPath = "\(dir)/\(app)/Contents/Info.plist"
        guard let plist = NSDictionary(contentsOfFile: plistPath) else { continue }

        if let docTypes = plist["CFBundleDocumentTypes"] as? [[String: Any]] {
            let typeCount = docTypes.count
            totalTypes += typeCount
            if typeCount > 0 {
                print("  \(app): \(typeCount) document types")
                for docType in docTypes.prefix(3) {
                    if let exts = docType["CFBundleTypeExtensions"] as? [String] {
                        let name = docType["CFBundleTypeName"] as? String ?? "unnamed"
                        print("    - \(name): \(exts.prefix(5).joined(separator: ", "))\(exts.count > 5 ? "..." : "")")
                    }
                }
                if typeCount > 3 { print("    ... and \(typeCount - 3) more") }
            }
        }
    }
}

print("\n  Found \(totalApps) apps across \(appDirs.joined(separator: ", "))")
print("  Sampled document types from first 5 apps per directory")

print("\n=== Spike Complete ===")
print("\nKey findings to record:")
print("  1. Did a confirmation dialog appear during Test 3? (YES/NO)")
print("  2. Were all API calls successful? (check return codes above)")
print("  3. Could we enumerate app document types? (Test 5)")
print("  4. How fast were bulk queries? (Test 4)")
