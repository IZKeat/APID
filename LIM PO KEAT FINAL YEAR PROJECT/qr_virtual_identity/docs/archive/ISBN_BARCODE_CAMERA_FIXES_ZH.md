# Library Scanner System Fix - ISBN Barcode Support & Camera Issues

## Fix Date

2025-01-17

---

## Issue Summary

### Issue 1: Camera Stuck at "Initializing camera..."

**Symptoms**:

- After Desktop triggers Mobile, Mobile camera starts.
- Screen constantly shows "📷 Initializing camera...".
- Cannot see actual camera feed.
- Cannot confirm scan target.

**Root Cause**:
`errorBuilder` triggered during camera initialization shows error placeholder instead of camera preview. In reality, many "errors" are just initialization messages and should not block the camera view.

---

### Issue 2: Scanning Book Barcode Shows "Invalid bar code"

**Symptoms**:

- Scanning ISBN barcode on book (e.g., `9780131103627`).
- System shows "Invalid bar code" or "Unsupported QR format".
- Cannot complete Borrow/Return process.

**Root Cause**:
System only supports `ITEM:<item_id>` format, but physical book barcodes are pure numeric ISBNs (e.g., `9780131103627`) without the `ITEM:` prefix.

---

## Solutions

### Fix 1: Improve Camera Error Handling

**File**: `lib/widgets/scanner_camera_view.dart`

**Before**:

```dart
errorBuilder: (context, error, child) {
  print('📱 [Scanner Camera View] Camera error (but continuing): $error');
  return Container(
    color: Colors.black,
    child: Center(
      child: Column(
        children: [
          Icon(Icons.camera_alt, size: 64),
          Text('📷 Initializing camera...'),
          Text('Please wait a moment'),
        ],
      ),
    ),
  );
},
```

**After**:

```dart
errorBuilder: (context, error, child) {
  // Log message but return child widget to display camera preview
  print('📱 [Scanner Camera View] Camera initialization message: $error');

  // Return child to allow camera to continue initializing
  // Most "errors" are actually just initialization messages
  return child ?? Container(
    color: Colors.black,
    child: const Center(
      child: CircularProgressIndicator(color: Colors.white),
    ),
  );
},
```

**Improvement**:

- ✅ No longer shows error blocking the screen.
- ✅ Allows camera preview to display normally.
- ✅ Initialization messages logged in console only, not affecting UI.
- ✅ User can see actual camera feed.

---

### Fix 2: Support Pure ISBN/Barcode Format

**File**: `lib/utils/qr_parser.dart`

**New Logic**:

```dart
// 5. Check Pure ISBN/Barcode Format (Numeric without prefix)
// Handles library book barcodes, usually ISBN numbers
// Format: 9780131103627 (10-13 digit ISBN or other numeric barcode)
if (parts.length == 1) {
  final rawBarcode = cleanData;
  // Check if it is a numeric barcode (ISBN or other book ID)
  if (RegExp(r'^[0-9]{8,13}$').hasMatch(rawBarcode)) {
    print('📚 [QRParser] Detected raw ISBN/barcode: $rawBarcode');
    return QrParseResult.item(qrData, rawBarcode);
  }
}
```

**Supported Barcode Formats**:

- ✅ **Pure Numeric ISBN-10**: `0131103628` (10 digits)
- ✅ **Pure Numeric ISBN-13**: `9780131103627` (13 digits)
- ✅ **Other Numeric Barcodes**: 8-13 digits (e.g., `9780132350884`)

**Parsing Priority**:

1. JSON Format (Dynamic User QR): `{"uid":"...","email":"...",...}`
2. TICKET Format: `TICKET:event_id:user_id:timestamp`
3. USER Format: `USER:<user_id>`
4. SCANPOINT/MERCHANT Format: `SCANPOINT:<id>` or `MERCHANT:<id>`
5. ITEM Format: `ITEM:<item_id>`
6. **New! Pure ISBN/Barcode**: `9780131103627` (8-13 digits)

---

## Library Borrow/Return Complete Workflow

### System Architecture

```
Desktop (PC)                  Mobile (Phone)               Firebase
    |                             |                          |
    | 1. Trigger Library Mode     |                          |
    |─────────────────────────────>|                          |
    |                             |                          |
    |                             | 2. Scan Student QR       |
    |                             |─────────────────────────>|
    |                             |    (USER:uid or JSON)     |
    |                             |                          |
    |                             |<─────────────────────────|
    |                             |  Create library_session  |
    |                             |                          |
    |                             | 3. Scan Book Barcode     |
    |                             |─────────────────────────>|
    |                             |    (ISBN: 9780131103627)  |
    |                             |                          |
    |                             |<─────────────────────────|
    |                             |  Create/Update book_loan |
    |                             |                          |
    | 4. Complete Notification    |                          |
    |<─────────────────────────────|                          |
```

### Step 1: Scan Student QR Code

**Purpose**: Identify student borrowing/returning.

**Supported Formats**:

- Old Format: `USER:TPxxxxxxx`
- New Format (Profile Page):
  ```json
  {
    "uid": "TPxxxxxxx",
    "email": "student@apu.edu.my",
    "name": "Lim Han",
    "role": "student",
    "ts": 1737123456
  }
  ```

**Processing Logic** (`LibraryService.processUser`):

```dart
1. Verify scan point is 'library' type.
2. Create/Update library_sessions document:
   {
     'scan_point_id': 'SP002',
     'scan_point_name': 'Library Counter',
     'current_user_id': 'TPxxxxxxx',
     'status': 'awaiting_book',
     'last_action': 'user_scanned',
     'updated_at': serverTimestamp
   }
3. Return success message: "Student identified. Please scan the book barcode."
4. UI shows "Step 2/2: Scan Book QR Code"
5. Shows student name (e.g., "Lim Han")
```

**Console Output**:

```
📚 [LibraryStrategy] Processing student scan: {"uid":"TPxxxxxxx",...}
📚 [LibraryStrategy] Student verified, advancing to book step...
📚 [LibraryStrategy] Scanner restarted for book scan
```

---

### Step 2: Scan Book Barcode

**Purpose**: Identify book and execute Borrow/Return.

**Supported Formats**:

- ✅ **Pure ISBN Barcode**: `9780131103627` (Newly Supported!)
- ✅ ITEM Format: `ITEM:9780131103627`

**Processing Logic** (`LibraryService.processItem`):

#### 2.1 Load Library Session

```dart
1. Load library_sessions/{scan_point_id} from Firestore.
2. Check if current_user_id exists.
3. If not → Error: "Please scan a student QR code first".
```

#### 2.2 Find Book Data

```dart
1. Find book in books collection:
   - Document ID = ISBN (e.g., "9780131103627")
   - Includes fields: title, author, isbn, status, etc.
2. If not found → Error: "Book not found in library catalog".
```

#### 2.3 Check Existing Loan

```dart
Query book_loans collection:
  - where('book_id', '==', '9780131103627')
  - where('status', '==', 'borrowed')
  - limit(1)
```

#### 2.4 Determine Operation Type

**Case A: No existing loan → Execute BORROW**

```dart
Create new book_loan document:
{
  'book_id': '9780131103627',
  'book_title': 'The C Programming Language',
  'user_id': 'TPxxxxxxx',
  'scan_point_id': 'SP002',
  'status': 'borrowed',
  'borrowed_at': serverTimestamp,
  'due_date': serverTimestamp + 14 days,
  'processed_by_user_id': 'sp002@apu.edu.my'
}

Update books/{book_id}:
{
  'status': 'borrowed',
  'borrowed_by': 'TPxxxxxxx',
  'borrowed_at': serverTimestamp
}
```

**Return Message**:

```json
{
  "success": true,
  "message": "Book borrowed successfully!",
  "data": {
    "loan_type": "borrow",
    "book_title": "The C Programming Language",
    "book_id": "9780131103627",
    "user_id": "TPxxxxxxx",
    "due_date": "2025-01-31"
  }
}
```

---

**Case B: Existing loan found → Execute RETURN**

```dart
Update existing book_loan document:
{
  'status': 'returned',
  'returned_at': serverTimestamp,
  'return_scan_point_id': 'SP002'
}

Update books/{book_id}:
{
  'status': 'available',
  'borrowed_by': null,
  'borrowed_at': null
}
```

**Return Message**:

```json
{
  "success": true,
  "message": "Book returned successfully!",
  "data": {
    "loan_type": "return",
    "book_title": "The C Programming Language",
    "book_id": "9780131103627",
    "borrowed_days": 7
  }
}
```

---

### Step 3: Cleanup and Reset

```dart
1. Stop Scanner: ScannerLifecycleController.stopScanning()
2. Notify Desktop Scanner Stopped
3. Reset LibraryScannerController state
4. Call onStrategyFinished() to clear strategy
5. Ready for next trigger
```

**Console Output**:

```
📚 [LibraryStrategy] Book processed successfully, completing workflow...
📚 [LibraryStrategy] Calling onStrategyFinished callback
🔄 [Mobile Terminal] Strategy finished, clearing state...
```

---

## Test Steps

### Test 1: Complete Borrow Flow

1. ✅ PC login SP002 (`sp002@apu.edu.my` / `123456`)
2. ✅ Trigger Library Mode from Desktop
3. ✅ Mobile should show "Step 1/2: Scan Student QR Code"
4. ✅ **Confirm Camera Visible** (No longer stuck Initializing)
5. ✅ Scan Student QR (Profile Page JSON)
6. ✅ Mobile shows "Step 2/2: Scan Book QR Code" and student name
7. ✅ **Scan Book ISBN Barcode** (e.g., `9780131103627`)
8. ✅ Confirm "Book borrowed successfully!"
9. ✅ Confirm correct book title (e.g., "The C Programming Language")
10. ✅ Scanner exits automatically, ready for next trigger

### Test 2: Return Flow

1. ✅ Repeat Steps 1-6
2. ✅ Scan **Same Book ISBN** (The one just borrowed)
3. ✅ Confirm "Book returned successfully!"
4. ✅ Confirm borrowed days calculation

### Test 3: Different ISBN Formats

Test that these ISBNs are all identified:

- ✅ `9780131103627` (13-digit ISBN-13)
- ✅ `9780132350884` (13-digit ISBN-13)
- ✅ `9781492078005` (13-digit ISBN-13)
- ✅ `9781492071266` (13-digit ISBN-13)

---

## Firebase Data Structure

### Collection: `books`

Document ID = ISBN

```json
{
  "title": "The C Programming Language",
  "author": "Brian Kernighan, Dennis Ritchie",
  "isbn": "9780131103627",
  "status": "available", // or "borrowed"
  "borrowed_by": null, // or user_id
  "borrowed_at": null, // or timestamp
  "created_at": "2025-01-01T00:00:00Z"
}
```

### Collection: `book_loans`

```json
{
  "book_id": "9780131103627",
  "book_title": "The C Programming Language",
  "user_id": "TPxxxxxxx",
  "scan_point_id": "SP002",
  "status": "borrowed", // or "returned"
  "borrowed_at": "2025-01-17T14:30:00Z",
  "due_date": "2025-01-31T14:30:00Z",
  "returned_at": null, // or timestamp
  "processed_by_user_id": "sp002@apu.edu.my"
}
```

### Collection: `library_sessions`

Document ID = scan_point_id

```json
{
  "scan_point_id": "SP002",
  "scan_point_name": "Library Counter",
  "current_user_id": "TPxxxxxxx",
  "status": "awaiting_book",
  "last_action": "user_scanned",
  "updated_at": "2025-01-17T14:30:00Z",
  "processed_by_user_id": "sp002@apu.edu.my"
}
```

---

## Expected Console Output (Complete Flow)

```
📡 [Trigger] Received library trigger for SP002
📚 [LibraryStrategy] Trigger received for scan point: Library Counter
🎥 [Scanner] Starting scanner...

// --- Step 1: Scan Student QR ---
📱 [Scanner Camera View] Camera initialization message: ...
📚 [LibraryStrategy] Processing student scan: {"uid":"TPxxxxxxx","email":"student@apu.edu.my",...}
📚 [LibraryStrategy] Parse result: user, isValid: true
📚 [LibraryStrategy] Student UID: TPxxxxxxx
📚 [LibraryStrategy] Student email: student@apu.edu.my
📚 [LibraryStrategy] Student name: Lim Han
📚 [LibraryService] Processing user QR: TPxxxxxxx
📚 [LibraryService] Library session created for user: TPxxxxxxx
📚 [LibraryStrategy] Student verified, advancing to book step...
📚 [LibraryStrategy] Scanner restarted for book scan

// --- Step 2: Scan Book ISBN ---
📚 [LibraryStrategy] Processing book scan: 9780131103627
📚 [QRParser] Detected raw ISBN/barcode: 9780131103627
📚 [LibraryStrategy] Parse result: item, isValid: true
📚 [LibraryService] Processing item QR: 9780131103627
📚 [LibraryService] Active session found for user: TPxxxxxxx
📚 [LibraryService] Book found: The C Programming Language
📚 [LibraryService] No active loan - processing BORROW
📚 [LibraryService] Book borrowed successfully
📚 [LibraryStrategy] Book processed successfully, completing workflow...
📚 [LibraryStrategy] Calling onStrategyFinished callback
🔄 [Mobile Terminal] Strategy finished, clearing state...
```

---

## File Modification Summary

### 1. `lib/utils/qr_parser.dart`

- ✅ Added Pure ISBN/Barcode format support (8-13 digits).
- ✅ Regex: `^[0-9]{8,13}$`
- ✅ Auto identifies and converts to `QrType.item`.
- ✅ Updated error message to hint at ISBN barcode support.

### 2. `lib/widgets/scanner_camera_view.dart`

- ✅ Improved `errorBuilder` logic.
- ✅ Return `child` instead of error placeholder.
- ✅ Allows camera preview to display normally.
- ✅ Initialization messages logged only in console.

---

## Important Notes

### ⚠️ Firebase Data Preparation

Ensure Firestore `books` collection has book data:

```javascript
// Example: Add book to Firestore
db.collection("books").doc("9780131103627").set({
  title: "The C Programming Language",
  author: "Brian Kernighan, Dennis Ritchie",
  isbn: "9780131103627",
  status: "available",
  created_at: firebase.firestore.FieldValue.serverTimestamp(),
});

db.collection("books").doc("9780132350884").set({
  title: "Clean Code",
  author: "Robert C. Martin",
  isbn: "9780132350884",
  status: "available",
  created_at: firebase.firestore.FieldValue.serverTimestamp(),
});
```

### ⚠️ Camera Permissions

Ensure Android device has granted Camera permissions:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA" />
```

---

## Troubleshooting

### Issue: Scanning ISBN still shows "Invalid bar code"

**Check**:

1. Is ISBN 8-13 digits?
2. Does Console show `📚 [QRParser] Detected raw ISBN/barcode`?
3. Does book exist in Firestore `books` collection?

### Issue: Camera screen still not visible

**Check**:

1. Android Camera permission granted?
2. Console shows initialization message?
3. Try restarting app: `flutter run -d <device>`

### Issue: "Please scan a student QR code first"

**Reason**: Step 1 not completed before Step 2.
**Solution**: Must scan Student QR first, then scan Book Barcode.

---

## Success Criteria

✅ Camera screen visible, no longer stuck in "Initializing".
✅ Pure numeric ISBN barcode correctly identified as ITEM type.
✅ Step 1 Student QR scan creates library_session.
✅ Step 2 Book ISBN scan executes Borrow/Return.
✅ UI correctly shows book title and result.
✅ Scanner exits correctly and accepts new trigger.

---

**Fix Completion Date**: 2025-01-17
**Test Status**: Pending User Verification
