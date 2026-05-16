# Library Scanner Workflow Fixes

## Overview

Applied three critical fixes to resolve blocking bugs in the Library Scanner two-step workflow.

---

## Fix 1: Step 2 Processing State Reset

### Problem

After scanning a student QR (Step 1), the UI would get stuck at "Processing QR code…" and couldn't proceed to Step 2 (book scan).

### Root Cause

The processing state (`ScannerLifecycleController.isProcessing`) remained `true` after Step 1 completion, preventing Step 2 from scanning.

### Solution

**File:** `lib/scanner_modules/library/library_scanner_strategy.dart`

#### In `_handleStudentScan()`:

Added `setProcessing(false)` **before** restarting the scanner:

```dart
// Reset processing so Step 2 can scan again
ScannerLifecycleController.setProcessing(false);

// Delay to ensure UI updates before scanner resumes
await Future.delayed(const Duration(milliseconds: 120));

// Continue scanning for book
await ScannerLifecycleController.startScanning(...);
```

#### In `_handleBookScan()`:

Added `setProcessing(false)` at the **beginning** of the method:

```dart
Future<void> _handleBookScan(String rawValue) async {
  try {
    print('📚 [LibraryStrategy] Processing book scan: $rawValue');

    // Reset processing so Step 2 can actually process the book QR
    ScannerLifecycleController.setProcessing(false);

    // Parse QR code
    final result = QRParser.parse(rawValue);
    ...
}
```

---

## Fix 2: Camera Overlay Blocking Issue

### Problem

The library mode UI overlay was rendering as a full-screen `Container`, completely blocking the camera feed with a blue screen.

### Root Cause

- `buildUI()` returned a full `Container` widget
- `ScannerCameraView` wrapped it with `Positioned.fill`, making it cover the entire screen

### Solution

#### File: `lib/scanner_modules/library/library_scanner_strategy.dart`

Changed the overlay from a full `Container` to a **floating panel** using `Positioned`:

```dart
@override
Widget? buildUI(BuildContext context) {
  _context = context;

  if (!controller.isActive) {
    return null;
  }

  // Return as floating panel instead of full-screen container
  return Positioned(
    top: 20,
    left: 20,
    right: 20,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.85), // Semi-transparent
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Don't expand vertically
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header, progress bar, status, etc.
          ...
        ],
      ),
    ),
  );
}
```

#### File: `lib/widgets/scanner_camera_view.dart`

Removed the `Positioned.fill` wrapper since the strategy now provides its own positioning:

**Before:**

```dart
if (strategyOverlay != null) Positioned.fill(child: strategyOverlay!),
```

**After:**

```dart
if (strategyOverlay != null) strategyOverlay!,
```

---

## Fix 3: UI Update Timing

### Problem

The scanner would restart before the UI had a chance to update to "Step 2/2", causing visual glitches.

### Solution

**File:** `lib/scanner_modules/library/library_scanner_strategy.dart`

Added a **120ms delay** after student verification, before restarting the scanner:

```dart
// Reset processing so Step 2 can scan again
ScannerLifecycleController.setProcessing(false);

// Delay to ensure UI updates before scanner resumes
await Future.delayed(const Duration(milliseconds: 120));

// Continue scanning for book
await ScannerLifecycleController.startScanning(...);
```

This ensures:

1. Processing state is reset
2. UI has time to rebuild and show "Step 2/2"
3. Scanner resumes cleanly for book scan

---

## Testing Checklist

### Complete Workflow Test

1. ✅ Login as SP002 (`sp002@apu.edu.my` / `123456`)
2. ✅ Trigger library mode from desktop
3. ✅ Scan student QR code (JSON format from profile page)
4. ✅ Verify UI updates to "Step 2/2" with student name
5. ✅ Verify camera feed remains visible (no blue screen)
6. ✅ Verify "Processing QR code..." disappears after Step 1
7. ✅ Scan book QR code
8. ✅ Verify workflow completes successfully
9. ✅ Verify scanner exits and can receive new triggers

### Expected Console Output

```
📚 [LibraryStrategy] Processing student scan: {"uid":"...","email":"..."}
📚 [LibraryStrategy] Student verified, advancing to book step...
📚 [LibraryStrategy] Scanner restarted for book scan
📚 [LibraryStrategy] Processing book scan: ITEM:B001
📚 [LibraryStrategy] Book processed successfully, completing workflow...
📚 [LibraryStrategy] Calling onStrategyFinished callback
```

---

## Files Modified

1. **`lib/scanner_modules/library/library_scanner_strategy.dart`**

   - Added `setProcessing(false)` in `_handleStudentScan()` before scanner restart
   - Added `setProcessing(false)` at start of `_handleBookScan()`
   - Added 120ms delay before scanner restart
   - Changed `buildUI()` to return `Positioned` floating panel instead of full `Container`
   - Reduced opacity from 0.9 to 0.85 for better camera visibility

2. **`lib/widgets/scanner_camera_view.dart`**
   - Removed `Positioned.fill` wrapper from `strategyOverlay`
   - Strategy now controls its own positioning

---

## Impact

### Before Fixes

- ❌ Step 2 permanently stuck at "Processing QR code..."
- ❌ Camera feed blocked by blue full-screen overlay
- ❌ UI didn't update to show "Step 2/2"
- ❌ Workflow couldn't complete

### After Fixes

- ✅ Processing state properly resets between steps
- ✅ Camera feed visible with floating overlay at top
- ✅ UI smoothly transitions from Step 1 to Step 2
- ✅ Complete workflow executes successfully
- ✅ Scanner can be reused for new triggers

---

## Notes

- **No changes to `GenericQrProcessingService`** - routing logic unchanged
- **No changes to `MobileScannerTerminal`** - terminal routing unchanged
- **Fixes are contained to strategy and UI layer only**
- **Processing state management is now explicit and controlled**

---

## Date Applied

2025-01-17
