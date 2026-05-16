# 🔍 MERCHANT LOGIN ERROR - COMPREHENSIVE ANALYSIS REPORT

**Error:** `Failed to route merchant: [cloud_firestore/unavailable] The service is currently unavailable.`

**Reported Issue:** Users logging in as sp001@apu.edu.my and other scan point accounts encounter Firestore errors. Some show "unavailable", others show "record not found".

---

## 🎯 ROOT CAUSE IDENTIFICATION

### **CRITICAL BUG #1: Missing `owner_uid` for Access-Type Scan Points**

**Location:** `lib/utils/seed_service.dart` (Lines 148-220)

**Problem:**
The seed service creates scan points with 4 types: `commerce`, `library`, `access`, `booking`.

However, **only `commerce`, `library`, and `booking` types create owner user accounts:**

```dart
// Line 154-173: Creates owners for commerce and booking
if (spType == 'commerce' || spType == 'booking') {
  ownerCred = await _createAuthUser(
    email: '${scanPointId.toLowerCase()}@apu.edu.my',
    password: '123456',
  );
  // ... creates user document with role: 'merchant'
}

// Line 177-198: Creates owners for library
if (spType == 'library') {
  ownerCred = await _createAuthUser(
    email: '${scanPointId.toLowerCase()}@apu.edu.my',
    password: '123456',
  );
  // ... creates user document with role: 'merchant'
}

// Line 200-215: Creates scan_points document
await db.collection('scan_points').doc(scanPointId).set({
  'scan_point_id': scanPointId,
  'name': sp['name'],
  'type': spType,
  // ... other fields ...
  'owner_uid': ownerCred?.user?.uid,  // ⚠️ NULL for access type!
  'created_at': FieldValue.serverTimestamp(),
  'last_active': FieldValue.serverTimestamp(),
});
```

**Impact:**
- **SP003 (Main Gate Access)** - `type: 'access'` → NO owner created → `owner_uid: null`
- **SP006 (Lecture Hall B Attendance)** - `type: 'access'` → NO owner created → `owner_uid: null`

**Result:**
If someone tries to log in as `sp003@apu.edu.my` or `sp006@apu.edu.my`:
1. **No such user exists in Firebase Auth** → Login will fail at authentication stage
2. Even if they existed, the scan_points document would have `owner_uid: null`

---

### **CRITICAL BUG #2: Firestore Exception Swallowing in Login Flow**

**Location:** `lib/pages_common/login_page.dart` (Lines 165-240)

**Problem:**
The `_routeMerchantByScanPointType()` method catches ALL exceptions generically:

```dart
Future<void> _routeMerchantByScanPointType(
  String uid,
  Map<String, dynamic> userData,
) async {
  try {
    // Get scan_point_id from user document
    final scanPointId = userData['scan_point_id'] as String?;

    if (scanPointId == null || scanPointId.isEmpty) {
      throw Exception('Merchant user has no scan_point_id assigned');
    }

    print('📍 Fetching scan point: $scanPointId');

    // Fetch the scan point document
    final scanPointDoc = await FirebaseFirestore.instance
        .collection('scan_points')
        .doc(scanPointId)
        .get();  // ⚠️ This can throw FirebaseException

    if (!scanPointDoc.exists) {
      throw Exception('Scan point $scanPointId not found');
    }

    final scanPointData = scanPointDoc.data()!;
    final scanPointType = scanPointData['type'] as String?;
    // ... routing logic ...
    
  } catch (e) {  // ⚠️ Generic catch - hides actual error type
    print('❌ Merchant routing error: $e');
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to route merchant: ${e.toString()}'),
        backgroundColor: Colors.red.shade300,
      ),
    );
  }
}
```

**Why This Causes "unavailable" Error:**

If the **Firestore Emulator is not running** or **network connection fails**, the `.get()` call throws:
```
FirebaseException: [cloud_firestore/unavailable] The service is currently unavailable
```

This gets caught by the generic `catch (e)` block and displayed as:
```
Failed to route merchant: [cloud_firestore/unavailable] The service is currently unavailable.
```

**This is NOT a code bug - it's an infrastructure issue**, but the error message is confusing because it doesn't tell the user to:
1. Start the Firestore Emulator
2. Check network connectivity
3. Verify Firestore connection settings

---

### **CRITICAL BUG #3: Scan Point Document Fetch May Fail Silently**

**Location:** `lib/pages_desktop/merchant_dashboard_desktop.dart` (Lines 138-150)

**Problem:**
The desktop dashboard queries scan points by `owner_uid`, but if the query fails or returns empty:

```dart
final merchantSnap = await FirebaseFirestore.instance
    .collection('scan_points')
    .where('owner_uid', isEqualTo: uid)
    .limit(1)
    .get();

if (merchantSnap.docs.isEmpty) {
  // ⚠️ NO ERROR HANDLING - silently fails
  // User sees empty dashboard or errors downstream
  return;
}
```

**If `owner_uid` is null or missing:**
- Query returns empty result
- User sees blank dashboard
- No error message displayed

---

### **CRITICAL BUG #4: Field Name Inconsistency Check**

**Location:** Multiple files

**Finding:** Field name is **CONSISTENT** across all files:
- `seed_service.dart` Line 213: `'owner_uid': ownerCred?.user?.uid,`
- `scan_point_service.dart` Line 82: `ownerUid: data['owner_uid'] as String?,`
- `scan_point_service.dart` Line 217: `.where('owner_uid', isEqualTo: uid)`
- `merchant_dashboard_desktop.dart` Line 53: `.where('owner_uid', isEqualTo: uid)`

✅ **No field name mismatch found** (all use snake_case `owner_uid`)

---

## 📊 AFFECTED SCAN POINTS TABLE

| Scan Point ID | Name | Type | Owner Created? | owner_uid | Login Works? |
|---------------|------|------|----------------|-----------|--------------|
| SP001 | Smokey Café | commerce | ✅ Yes | ✅ Set | ✅ Yes |
| SP002 | Library Counter | library | ✅ Yes | ✅ Set | ✅ Yes |
| **SP003** | **Main Gate Access** | **access** | ❌ **NO** | ❌ **NULL** | ❌ **NO** |
| SP004 | Lab A Room Booking | booking | ✅ Yes | ✅ Set | ✅ Yes |
| SP005 | Campus Mart | commerce | ✅ Yes | ✅ Set | ✅ Yes |
| **SP006** | **Lecture Hall B** | **access** | ❌ **NO** | ❌ **NULL** | ❌ **NO** |

---

## 🔍 DETAILED ANALYSIS BY WORKFLOW STAGE

### **Stage 1: Firebase Authentication**

**Login Flow:**
```dart
// login_page.dart Line 97-107
final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: _emailController.text.trim(),  // e.g., "sp001@apu.edu.my"
  password: _passwordController.text.trim(),  // "123456"
);

final user = credential.user;
if (user == null) throw Exception("Login failed");
```

**Status:**
- ✅ **Works for:** sp001, sp002, sp004, sp005 (auth users exist)
- ❌ **Fails for:** sp003, sp006 (auth users **DO NOT EXIST**)

**Error Message (if sp003/sp006 login attempted):**
```
FirebaseAuthException: There is no user record corresponding to this identifier.
```

---

### **Stage 2: User Document Lookup**

**Code:**
```dart
// login_page.dart Line 110-117
final querySnapshot = await FirebaseFirestore.instance
    .collection('users')
    .where('email', isEqualTo: user.email)
    .limit(1)
    .get();

if (querySnapshot.docs.isEmpty) {
  // Check admins collection...
}
```

**Status:**
- ✅ **Works for:** sp001, sp002, sp004, sp005
- ❌ **Would fail for:** sp003, sp006 (but they never reach this stage due to auth failure)

---

### **Stage 3: Role-Based Routing**

**Code:**
```dart
// login_page.dart Line 129-145
final userData = querySnapshot.docs.first.data();
final role = userData['role'] ?? 'unknown';

print("👤 Logged in as ${userData['email']} | Role: $role");

if (!mounted) return;

if (role == 'student' || role == 'lecturer') {
  Navigator.pushReplacementNamed(context, Routes.home);
} else if (role == 'merchant') {
  await _routeMerchantByScanPointType(user.uid, userData);
} else {
  throw Exception("Unknown role: $role");
}
```

**Status:**
- ✅ **Works for:** sp001@apu.edu.my (role: 'merchant')
- ✅ **Works for:** sp002@apu.edu.my (role: 'merchant')
- ✅ **Works for:** sp004@apu.edu.my (role: 'merchant')
- ✅ **Works for:** sp005@apu.edu.my (role: 'merchant')

All merchant users have `role: 'merchant'` in their user documents (seed_service.dart Line 168).

---

### **Stage 4: Merchant Routing (Scan Point Fetch)**

**Code:**
```dart
// login_page.dart Line 165-240
Future<void> _routeMerchantByScanPointType(
  String uid,
  Map<String, dynamic> userData,
) async {
  try {
    final scanPointId = userData['scan_point_id'] as String?;

    if (scanPointId == null || scanPointId.isEmpty) {
      throw Exception('Merchant user has no scan_point_id assigned');
    }

    print('📍 Fetching scan point: $scanPointId');

    final scanPointDoc = await FirebaseFirestore.instance
        .collection('scan_points')
        .doc(scanPointId)
        .get();  // ⚠️ THIS IS WHERE "[unavailable]" ERROR OCCURS

    if (!scanPointDoc.exists) {
      throw Exception('Scan point $scanPointId not found');
    }

    final scanPointData = scanPointDoc.data()!;
    final scanPointType = scanPointData['type'] as String?;
    final scanPointName = scanPointData['name'] as String? ?? 'Unknown';

    print('🎯 Scan Point: $scanPointName | Type: $scanPointType');
    
    // ... platform-based routing ...
  } catch (e) {
    print('❌ Merchant routing error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to route merchant: ${e.toString()}'),
        backgroundColor: Colors.red.shade300,
      ),
    );
  }
}
```

**Possible Failure Points:**

1. **Firestore Emulator Not Running:**
   - Error: `[cloud_firestore/unavailable] The service is currently unavailable.`
   - Cause: Firestore SDK cannot connect to `localhost:8080`
   - Fix: Start emulators with `firebase emulators:start`

2. **Scan Point Document Missing:**
   - Error: `Scan point SP001 not found`
   - Cause: Database not seeded or document deleted
   - Fix: Run seed service

3. **Network Issues:**
   - Error: `[cloud_firestore/unavailable]` or timeout
   - Cause: Firewall, network disconnection
   - Fix: Check network and emulator connectivity

4. **User Missing `scan_point_id` Field:**
   - Error: `Merchant user has no scan_point_id assigned`
   - Cause: User document created without `scan_point_id` field
   - Fix: Update user document or re-run seed

---

### **Stage 5: Platform Routing**

**Code:**
```dart
// login_page.dart Line 206-230
if (Platform.isWindows || Platform.isMacOS) {
  print('💻 Routing to Desktop Dashboard for $scanPointType');
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const MerchantDashboardDesktop(),
    ),
  );
} else if (kIsWeb) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('QR Scanner is disabled on Web...'),
    ),
  );
} else {
  print('📱 Routing to Mobile Scanner Terminal for $scanPointType');
  Navigator.pushReplacementNamed(context, Routes.mobileScannerTerminal);
}
```

**Status:**
- ✅ **Desktop:** Routes to `MerchantDashboardDesktop` (generic, works for all types)
- ✅ **Mobile:** Routes to `Routes.mobileScannerTerminal`
- ✅ **Web:** Shows warning (scanner disabled)

**No issues found here.**

---

### **Stage 6: Desktop Dashboard Initialization**

**Code:**
```dart
// merchant_dashboard_desktop.dart Line 38-71
@override
void initState() {
  super.initState();
  final uid = _user?.uid;

  if (uid != null) {
    // Stream scan_points belonging to this logged-in user
    _merchantStream = FirebaseFirestore.instance
        .collection('scan_points')
        .where('owner_uid', isEqualTo: uid)  // ⚠️ Query by owner_uid
        .limit(1)
        .snapshots();

    // Update last_active timestamp
    FirebaseFirestore.instance
        .collection('scan_points')
        .where('owner_uid', isEqualTo: uid)
        .limit(1)
        .get()
        .then((snap) {
          if (snap.docs.isNotEmpty) {
            snap.docs.first.reference.update({
              'last_active': FieldValue.serverTimestamp(),
            });
          }
        });
    
    // ... scanner status listener ...
  }
}
```

**Potential Issue:**
If `owner_uid` field is missing or null in the scan_points document:
- Query returns **empty result** (no errors thrown)
- Dashboard shows **blank UI** or **"No data"** state
- No error message displayed to user

**For SP003/SP006:**
Since these scan points have `owner_uid: null`, any user trying to access them would see an empty dashboard.

---

## 🧩 DEPENDENCY CHAIN ANALYSIS

### **Merchant Login Dependency Graph:**

```
1. Firebase Auth User Exists (sp001@apu.edu.my)
   ↓
2. Firestore User Document Exists (users/{uid})
   ├─ email: "sp001@apu.edu.my"
   ├─ role: "merchant"
   └─ scan_point_id: "SP001"  ⚠️ REQUIRED
   ↓
3. Firestore Scan Point Document Exists (scan_points/SP001)
   ├─ scan_point_id: "SP001"
   ├─ name: "Smokey Café"
   ├─ type: "commerce"
   ├─ owner_uid: "{uid}"  ⚠️ MUST MATCH USER UID
   └─ active: true
   ↓
4. Desktop Dashboard Queries by owner_uid
   ↓
5. Success: Dashboard displays scan point data
```

**Broken Links:**

| Link | SP001-SP002-SP004-SP005 | SP003-SP006 |
|------|-------------------------|-------------|
| Auth User | ✅ Exists | ❌ **Missing** |
| User Document | ✅ Exists | ❌ **Missing** |
| scan_point_id in User | ✅ Set | N/A |
| Scan Point Document | ✅ Exists | ✅ Exists |
| owner_uid in Scan Point | ✅ Set | ❌ **NULL** |
| Dashboard Query | ✅ Works | ❌ **Fails** |

---

## 🔧 SERVICES ANALYSIS

### **ScanPointService.getCurrentScanPointForLoggedInUser()**

**Location:** `lib/services/scan_point_service.dart` (Lines 165-237)

**Logic:**
1. Check if user is logged in
2. Get user document from `users/{uid}`
3. Extract `scan_point_id` field from user document
4. If found, fetch scan point by ID
5. If not found, **fallback**: query scan_points by `owner_uid`

**Code:**
```dart
// Step 1: Check user document for scan_point_id field
final userDoc = await _db.collection('users').doc(uid).get();

if (userDoc.exists && userDoc.data() != null) {
  final userData = userDoc.data()!;
  final scanPointId = userData['scan_point_id'] as String?;

  if (scanPointId != null && scanPointId.isNotEmpty) {
    print('📍 [ScanPointService] Found scan_point_id in user doc: $scanPointId');

    final scanPointDoc = await _db
        .collection('scan_points')
        .doc(scanPointId)
        .get();

    if (scanPointDoc.exists && scanPointDoc.data() != null) {
      final scanPoint = ScanPoint.fromDocument(scanPointDoc);
      print('✅ [ScanPointService] Found scan point: ${scanPoint.name}');
      return scanPoint;
    }
  }
}

// Step 2: Try to find scan point by owner_uid
print('🔍 [ScanPointService] Searching by owner_uid: $uid');
final ownerQuery = await _db
    .collection('scan_points')
    .where('owner_uid', isEqualTo: uid)
    .limit(1)
    .get();

if (ownerQuery.docs.isNotEmpty) {
  final scanPoint = ScanPoint.fromDocument(ownerQuery.docs.first);
  print('✅ [ScanPointService] Found scan point by owner_uid: ${scanPoint.name}');
  return scanPoint;
}

// No scan point found
print('❌ [ScanPointService] No scan point found for user: $uid');
return null;
```

**Status:**
- ✅ **Works for:** sp001, sp002, sp004, sp005
  - Step 1 succeeds (scan_point_id exists in user document)
  - Returns correct scan point
  
**NOTE:** This service is **not currently used** in the login flow. The login page fetches scan points directly.

---

## 🚨 ERROR MESSAGES DECODED

### **Error 1: "Failed to route merchant: [cloud_firestore/unavailable] The service is currently unavailable."**

**Root Cause:**
- Firestore Emulator is **not running**
- OR Firestore connection settings are incorrect
- OR Network connectivity issues

**Code Location:** `login_page.dart` Line 189 (scanPointDoc.get() throws exception)

**Fix:**
1. Start Firestore Emulator: `firebase emulators:start`
2. Verify emulator is running on `localhost:8080`
3. Check `firebase.json` configuration
4. Ensure app connects to emulator (not production Firestore)

---

### **Error 2: "User record not found in Firestore"**

**Root Cause:**
- User logged in with Firebase Auth successfully
- BUT no matching document exists in `users` or `admins` collection

**Code Location:** `login_page.dart` Line 120

**Affected Users:** sp003@apu.edu.my, sp006@apu.edu.my (if they existed in auth)

**Fix:**
1. Run seed service to create user documents
2. OR manually create user document in Firestore

---

### **Error 3: "Merchant user has no scan_point_id assigned"**

**Root Cause:**
- User document exists
- BUT `scan_point_id` field is missing or empty

**Code Location:** `login_page.dart` Line 175

**Fix:**
Update user document:
```dart
await db.collection('users').doc(uid).update({
  'scan_point_id': 'SP001',  // Assign scan point
});
```

---

### **Error 4: "Scan point SP001 not found"**

**Root Cause:**
- User document has `scan_point_id: 'SP001'`
- BUT `scan_points/SP001` document does not exist

**Code Location:** `login_page.dart` Line 191

**Fix:**
1. Run seed service to create scan_points
2. OR manually create scan point document

---

## 📋 COMPREHENSIVE ISSUE CHECKLIST

### **Database Issues:**
- [ ] Firestore Emulator running? (`firebase emulators:start`)
- [ ] Seed service executed? (Creates users + scan_points)
- [ ] SP001-SP006 scan points exist in `scan_points` collection?
- [ ] sp001@apu.edu.my user exists in Firebase Auth?
- [ ] sp001@apu.edu.my user document exists in `users` collection?
- [ ] User document has `scan_point_id: 'SP001'` field?
- [ ] Scan point document has `owner_uid: '{uid}'` field?
- [ ] **SP003/SP006 access points have NO owners** (by design)?

### **Code Issues:**
- [x] Field name consistency (owner_uid vs ownerUid) ✅ **PASS**
- [ ] Error handling catches specific exceptions (not generic)?
- [ ] User feedback shows clear error messages?
- [ ] Routing logic handles all scan point types?

### **Infrastructure Issues:**
- [ ] Firestore Emulator accessible at `localhost:8080`?
- [ ] Firebase config (`firebase.json`) correct?
- [ ] App configured to use Firestore Emulator?
- [ ] Network connectivity working?

---

## 🎯 RECOMMENDED FIXES

### **Fix #1: Create Owners for Access-Type Scan Points (OPTIONAL)**

**Location:** `lib/utils/seed_service.dart`

**Change:**
```dart
// BEFORE (Line 154-156):
if (spType == 'commerce' || spType == 'booking') {
  ownerCred = await _createAuthUser(...);
  // ...
}

// AFTER:
if (spType == 'commerce' || spType == 'booking' || spType == 'access') {
  ownerCred = await _createAuthUser(
    email: '${scanPointId.toLowerCase()}@apu.edu.my',
    password: '123456',
  );

  await db.collection('users').doc(ownerCred.user!.uid).set({
    'uid': ownerCred.user!.uid,
    'email': '${scanPointId.toLowerCase()}@apu.edu.my',
    'first_name': sp['name'],
    'last_name': '',
    'role': 'merchant',
    'qr_status': 'active',
    'scan_point_id': scanPointId,
    'total_spent': 0.0,
    'balance': 0.0,
    'last_login': FieldValue.serverTimestamp(),
    'is_blacklisted': false,
    'access_permissions': [],
  });
}
```

**Impact:**
- Creates sp003@apu.edu.my and sp006@apu.edu.my users
- Sets `owner_uid` in scan_points/SP003 and scan_points/SP006
- Allows login and dashboard access for access point operators

**Alternative:** Keep access points without owners (mobile-only operation)

---

### **Fix #2: Improve Error Handling in Merchant Routing**

**Location:** `lib/pages_common/login_page.dart`

**Change:**
```dart
// BEFORE (Line 237-240):
} catch (e) {
  print('❌ Merchant routing error: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Failed to route merchant: ${e.toString()}'),
      backgroundColor: Colors.red.shade300,
    ),
  );
}

// AFTER:
} on FirebaseException catch (e) {
  print('❌ Firestore error: ${e.code} - ${e.message}');
  
  String errorMessage;
  if (e.code == 'unavailable') {
    errorMessage = 'Database unavailable. Please ensure Firestore Emulator is running.';
  } else if (e.code == 'permission-denied') {
    errorMessage = 'Permission denied. Check Firestore security rules.';
  } else {
    errorMessage = 'Database error: ${e.message}';
  }
  
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorMessage),
      backgroundColor: Colors.red.shade300,
      duration: const Duration(seconds: 5),
    ),
  );
} catch (e) {
  print('❌ Merchant routing error: $e');
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Login failed: ${e.toString()}'),
      backgroundColor: Colors.red.shade300,
    ),
  );
}
```

**Impact:**
- Provides clearer error messages to users
- Distinguishes between Firestore connection issues vs. data issues
- Helps users troubleshoot (e.g., "Start emulator")

---

### **Fix #3: Add Dashboard Fallback for Empty Scan Point Query**

**Location:** `lib/pages_desktop/merchant_dashboard_desktop.dart`

**Change:**
```dart
// BEFORE (Line 138-150):
final merchantSnap = await FirebaseFirestore.instance
    .collection('scan_points')
    .where('owner_uid', isEqualTo: uid)
    .limit(1)
    .get();

if (merchantSnap.docs.isEmpty) {
  return;  // ⚠️ Silent failure
}

// AFTER:
final merchantSnap = await FirebaseFirestore.instance
    .collection('scan_points')
    .where('owner_uid', isEqualTo: uid)
    .limit(1)
    .get();

if (merchantSnap.docs.isEmpty) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No scan point assigned to your account. Please contact administrator.',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
  }
  return;
}
```

**Impact:**
- Users see clear error message if scan point not found
- Prevents silent failures and confusion

---

### **Fix #4: Add Pre-Login Validation**

**Location:** `lib/pages_common/login_page.dart`

**Change:** Add validation before routing:

```dart
// After Line 129 (before role routing)
// Verify scan_point_id exists for merchants
if (role == 'merchant') {
  final scanPointId = userData['scan_point_id'] as String?;
  if (scanPointId == null || scanPointId.isEmpty) {
    throw Exception(
      'Your account is not assigned to a scan point. Please contact administrator.',
    );
  }
  
  // Verify scan point exists
  final scanPointDoc = await FirebaseFirestore.instance
      .collection('scan_points')
      .doc(scanPointId)
      .get();
  
  if (!scanPointDoc.exists) {
    throw Exception(
      'Scan point $scanPointId not found. Please contact administrator.',
    );
  }
}
```

**Impact:**
- Catches configuration errors early
- Provides actionable error messages

---

## 📌 TESTING CHECKLIST

After implementing fixes, test these scenarios:

### **Scenario 1: Successful Login (sp001@apu.edu.my)**
- [ ] User exists in Firebase Auth ✅
- [ ] User document exists in `users` collection ✅
- [ ] User document has `role: 'merchant'` ✅
- [ ] User document has `scan_point_id: 'SP001'` ✅
- [ ] Scan point SP001 exists ✅
- [ ] Scan point has `owner_uid` matching user ✅
- [ ] Desktop dashboard loads ✅
- [ ] Dashboard displays scan point name ✅
- [ ] Scanner trigger button works ✅

### **Scenario 2: Firestore Emulator Not Running**
- [ ] Login fails at scan point fetch ❌
- [ ] Error message: "Database unavailable. Please ensure Firestore Emulator is running." ✅
- [ ] User understands what to do ✅

### **Scenario 3: Scan Point Missing**
- [ ] Login succeeds up to scan point fetch ✅
- [ ] Error message: "Scan point SP001 not found. Please contact administrator." ✅

### **Scenario 4: Access Point Login (sp003@apu.edu.my - AFTER FIX #1)**
- [ ] User exists in Firebase Auth ✅
- [ ] User document exists ✅
- [ ] Scan point SP003 exists ✅
- [ ] Scan point has `owner_uid` set ✅
- [ ] Login succeeds ✅
- [ ] Desktop dashboard loads ✅

### **Scenario 5: Missing scan_point_id in User Document**
- [ ] Login succeeds up to routing ✅
- [ ] Error message: "Merchant user has no scan_point_id assigned" ✅

---

## 🎓 SUMMARY

### **What's Working:**
✅ Firebase Authentication for sp001, sp002, sp004, sp005  
✅ User document creation and storage  
✅ Scan point document creation  
✅ Field naming consistency (owner_uid)  
✅ Platform-based routing (desktop/mobile)  
✅ ScanPointService logic

### **What's Broken:**
❌ Access-type scan points (SP003, SP006) have no owners  
❌ Generic exception handling hides root cause  
❌ "unavailable" error when emulator not running  
❌ Silent failures in dashboard initialization  
❌ No pre-login validation for merchant configuration

### **Action Required:**
1. **Immediate:** Start Firestore Emulator (`firebase emulators:start`)
2. **Immediate:** Run seed service to create all documents
3. **Optional:** Implement Fix #1 to create access point owners
4. **Recommended:** Implement Fix #2 for better error messages
5. **Recommended:** Implement Fix #3 for dashboard error handling
6. **Recommended:** Implement Fix #4 for pre-login validation

---

**END OF ANALYSIS REPORT**
