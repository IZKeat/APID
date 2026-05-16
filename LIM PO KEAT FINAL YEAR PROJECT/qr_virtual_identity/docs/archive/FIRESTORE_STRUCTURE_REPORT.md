# 🔍 FIRESTORE DATABASE STRUCTURAL REPORT

**Project:** QR Virtual Identity System  
**Database:** po-keat-fyp  
**Date:** November 18, 2025  
**Mode:** READ-ONLY INSPECTION

---

## 📋 ROOT COLLECTION LIST

### ✅ **Active Collections (8)**

1. `admins` - 1 document
2. `users` - 7 documents
3. `scan_points` - 6 documents
4. `interactions` - 14 documents
5. `logs` - 14 documents
6. `events` - 6 documents
7. `user_tickets` - 5 documents
8. `books` - 30 documents

### ⚪ **Empty Collections (7)**

1. `guest_users` - No documents
2. `guest_tickets` - No documents
3. `book_loans` - No documents
4. `library_sessions` - No documents
5. `ticket_scans` - No documents
6. `scanner_triggers` - No documents
7. `scanner_status` - No documents

---

## 📊 DETAILED COLLECTION SCHEMAS

### 1️⃣ **Collection: `admins`**

**Document Count:** 1  
**Sample IDs:** `buu2YxDmX1MzsJ92WeIz3TmpWLB3`

**Schema:**

```json
{
  "admin_id": "string",
  "email": "string",
  "name": "string",
  "privilege": "array<object>",
  "role": "string",
  "uid": "string",
  "created_at": "Timestamp"
}
```

**Consistency:** ✅ All fields consistent  
**Purpose:** Stores admin user accounts with elevated privileges  
**Key Characteristics:**

- Single admin account present
- Privileges stored as array
- Linked to Firebase Auth via `uid`

---

### 2️⃣ **Collection: `users`**

**Document Count:** 7  
**Sample IDs:** `4moVpDz5gTNKWhtSaP6sbwUeg0K3`, `ANrxLQxk5AQUq3Wl128xHK29HeM2`, ...

**Schema:**

```json
{
  "balance": "integer",
  "email": "string",
  "first_name": "string",
  "last_name": "string",
  "qr_status": "string",
  "role": "string",
  "uid": "string",
  "last_login": "Timestamp",
  "total_spent": "double",

  // Optional/Inconsistent fields:
  "total_interactions": "integer", // Present in 3/7 docs
  "active_tickets": "integer", // Present in 3/7 docs
  "cancelled_tickets": "integer", // Present in 3/7 docs
  "events_joined": "integer", // Present in 3/7 docs
  "scan_point_id": "string" // Present in 4/7 docs
}
```

**Consistency:** ⚠️ **5 inconsistent fields**

- `total_interactions` (3/7 docs)
- `active_tickets` (3/7 docs)
- `cancelled_tickets` (3/7 docs)
- `events_joined` (3/7 docs)
- `scan_point_id` (4/7 docs)

**Purpose:** Student/lecturer accounts with QR identity  
**Key Characteristics:**

- Mix of students and scan point operators
- Some users have event-related stats, others don't
- Balance system for commerce transactions
- QR status tracking (active/inactive)

**⚠️ Red Flag:** Inconsistent field presence suggests partial migration or incomplete data initialization

---

### 3️⃣ **Collection: `scan_points`**

**Document Count:** 6  
**Sample IDs:** `SP001`, `SP002`, `SP003`, `SP004`, `SP005`, `SP006`

**Schema:**

```json
{
  "active": "boolean",
  "description": "string",
  "location": "string",
  "name": "string",
  "owner_uid": "string",
  "qr_code": "string",
  "scan_point_id": "string",
  "tags": "array<object>",
  "type": "string", // commerce | library | access | booking
  "created_at": "Timestamp",
  "revenue": "double",
  "scan_count": "integer",
  "today_revenue": "integer",
  "interaction_count": "integer",
  "last_active": "Timestamp",

  // Optional:
  "average_transaction": "double" // Present in 2/6 docs
}
```

**Consistency:** ⚠️ **1 inconsistent field**

- `average_transaction` (2/6 docs) - Only present for commerce type

**Purpose:** Physical scanning terminals (merchants, library desks, gates, booking counters)  
**Key Characteristics:**

- Multi-type system: commerce, library, access, booking
- Revenue tracking for commerce types
- Owned by specific users
- Active/inactive status control

**✅ Modern Design:** This replaces the older "merchants" collection

---

### 4️⃣ **Collection: `interactions`**

**Document Count:** 14  
**Sample IDs:** `INT001`, `INT002`, `INT003`, `INT004`, `INT005`, ...

**Schema:**

```json
{
  "interaction_id": "string",
  "scan_point_id": "string",
  "scan_point_name": "string",
  "status": "string", // success | pending | denied
  "timestamp": "Timestamp",
  "type": "string", // purchase | refund | borrow | return | entry | exit | attendance | booking
  "user_email": "string",
  "user_id": "string",
  "remarks": "string",
  "created_at": "Timestamp",

  // Type-specific fields (library):
  "book_id": "string", // 3/14 docs
  "book_title": "string", // 3/14 docs
  "due_date": "Timestamp", // 2/14 docs

  // Type-specific fields (access):
  "access_point": "string", // 3/14 docs

  // Type-specific fields (commerce):
  "amount": "double", // 6/14 docs
  "currency": "string", // 6/14 docs
  "payment_method": "string", // 6/14 docs
  "receipt_id": "string", // 6/14 docs

  // Type-specific fields (attendance):
  "class_code": "string", // 1/14 docs
  "class_name": "string", // 1/14 docs

  // Type-specific fields (booking):
  "booking_id": "string", // 1/14 docs
  "resource_name": "string", // 1/14 docs
  "slot_start": "Timestamp", // 1/14 docs
  "slot_end": "Timestamp" // 1/14 docs
}
```

**Consistency:** ⚠️ **12 inconsistent fields** (expected due to polymorphic design)

**Purpose:** Unified transaction/activity log for all scan point interactions  
**Key Characteristics:**

- Polymorphic schema supporting 8 interaction types
- Each type has specific fields
- Replaces the older "transactions" collection
- Acts as audit trail for all campus activities

**✅ Modern Design:** Unified interaction model with type-specific fields

---

### 5️⃣ **Collection: `logs`**

**Document Count:** 14  
**Sample IDs:** Auto-generated Firestore IDs

**Schema:**

```json
{
  "action": "string",
  "by": "string",
  "detail": "string",
  "timestamp": "Timestamp"
}
```

**Consistency:** ✅ All fields consistent  
**Purpose:** System audit log for administrative actions  
**Key Characteristics:**

- Simple, consistent structure
- Tracks who did what and when
- General-purpose logging

---

### 6️⃣ **Collection: `events`**

**Document Count:** 6  
**Sample IDs:** `EVT001`, `EVT002`, `EVT003`, `EVT004`, `EVT005`, `EVT006`

**Schema:**

```json
{
  "capacity": "integer",
  "category": "string",
  "date": "string", // YYYY-MM-DD format
  "description": "string",
  "end_time": "string",
  "event_id": "string",
  "image_url": "string",
  "is_active": "boolean",
  "is_public": "boolean",
  "location": "string",
  "name": "string",
  "organizer": "string",
  "start_time": "string",
  "tags": "array<object>",
  "created_at": "Timestamp",
  "updated_at": "Timestamp",
  "current_attendees": "integer",

  // Optional:
  "attendees": "array<object>" // Present in 4/6 docs
}
```

**Consistency:** ⚠️ **1 inconsistent field**

- `attendees` array (4/6 docs) - Some events don't track attendee list

**Purpose:** Campus event management and registration  
**Key Characteristics:**

- Public/private event control
- Capacity management
- Date/time stored as strings (not Timestamps)
- Category and tag-based organization

**⚠️ Design Note:** `attendees` field inconsistency may indicate lazy initialization

---

### 7️⃣ **Collection: `user_tickets`**

**Document Count:** 5  
**Sample IDs:** `TKT001`, `TKT002`, `TKT003`, `TKT004`, `TKT005`

**Schema:**

```json
{
  "category": "string",
  "event_date": "string",
  "event_id": "string",
  "event_location": "string",
  "event_name": "string",
  "joined_at": "Timestamp",
  "status": "string", // active | cancelled
  "ticket_id": "string",
  "user_email": "string",
  "user_id": "string",
  "created_at": "Timestamp",

  // Optional:
  "cancelled_at": "Timestamp" // Present in 1/5 docs
}
```

**Consistency:** ⚠️ **1 inconsistent field**

- `cancelled_at` (1/5 docs) - Only set when ticket is cancelled

**Purpose:** Event tickets for registered users  
**Key Characteristics:**

- Links users to events
- Status tracking (active/cancelled)
- Denormalized event data for quick access
- Cancellation timestamp when applicable

**✅ Expected Behavior:** `cancelled_at` only appears on cancelled tickets

---

### 8️⃣ **Collection: `books`**

**Document Count:** 30  
**Sample IDs:** `9780000000001`, `9780000000002`, ... (ISBN as document ID)

**Schema:**

```json
{
  "authors": "string",
  "availability": "boolean",
  "call_number": "null",
  "edition": "null",
  "isbn": "string",
  "publisher": "string",
  "subjects": "null",
  "title": "string",
  "year": "integer",
  "created_at": "Timestamp"
}
```

**Consistency:** ✅ All fields consistent  
**Purpose:** Library book catalog  
**Key Characteristics:**

- ISBN used as document ID
- Availability tracking
- Some fields consistently null (call_number, edition, subjects)
- Simple book metadata

**⚠️ Design Note:** Several fields are always `null` - may be placeholder for future features

---

## 🔴 EMPTY COLLECTIONS ANALYSIS

### **Expected but Unused Collections**

1. **`guest_users`** - For Google Sign-In guest accounts

   - **Status:** Empty
   - **Purpose:** Store guest user profiles from public sign-in
   - **Impact:** Guest mode not yet tested/used

2. **`guest_tickets`** - For guest event registrations

   - **Status:** Empty
   - **Purpose:** Event tickets for non-student guests
   - **Impact:** Guest ticketing system not yet utilized

3. **`book_loans`** - Active library borrowing records

   - **Status:** Empty
   - **Purpose:** Track which books are borrowed by whom
   - **Impact:** Library system functional but no active loans

4. **`library_sessions`** - Two-step library workflow state

   - **Status:** Empty
   - **Purpose:** Temporary session storage (scan student → scan book)
   - **Impact:** No active library sessions

5. **`ticket_scans`** - Ticket verification audit log

   - **Status:** Empty
   - **Purpose:** Log all ticket scan attempts
   - **Impact:** Ticket verification feature not yet used

6. **`scanner_triggers`** - Cross-device scanner commands

   - **Status:** Empty
   - **Purpose:** Send trigger/stop commands to mobile scanner
   - **Impact:** Cross-device scanner sync not being used

7. **`scanner_status`** - Real-time scanner state sync
   - **Status:** Empty
   - **Purpose:** Sync scanner active/idle state across devices
   - **Impact:** Scanner status sync not in use

---

## 🎯 ARCHITECTURAL SUMMARY

### **Core Design Patterns**

1. **✅ Multi-Type Scan Point System**

   - Single `scan_points` collection handles commerce, library, access, booking
   - Type-based polymorphism for different behaviors

2. **✅ Unified Interaction Model**

   - `interactions` collection replaces old `transactions`
   - Polymorphic schema with type-specific fields
   - Supports 8 interaction types

3. **✅ Event & Ticketing System**

   - Dual ticket system: `user_tickets` (registered) + `guest_tickets` (public)
   - Verification audit trail via `ticket_scans`

4. **✅ Library Management**

   - ISBN-based book catalog
   - Two-step workflow: user scan → book scan
   - Session state in `library_sessions`

5. **✅ Cross-Device Scanner Sync**
   - Desktop → Mobile trigger system
   - Real-time status synchronization

---

## ⚠️ IDENTIFIED ISSUES

### **1. Inconsistent Field Initialization**

**Collection:** `users`  
**Issue:** 5 fields not present in all documents

```
total_interactions: 3/7 docs
active_tickets: 3/7 docs
cancelled_tickets: 3/7 docs
events_joined: 3/7 docs
scan_point_id: 4/7 docs
```

**Impact:** Queries/aggregations may fail or return incorrect results  
**Recommendation:** Initialize all fields with default values (0 for counters, null for optional)

---

### **2. Null Fields in Books**

**Collection:** `books`  
**Issue:** `call_number`, `edition`, `subjects` always null
**Impact:** Wasted storage and misleading schema  
**Recommendation:** Either populate these fields or remove them

---

### **3. String-based Dates in Events**

**Collection:** `events`  
**Issue:** `date`, `start_time`, `end_time` stored as strings, not Timestamps
**Impact:** Difficult to query/sort by date range  
**Recommendation:** Consider using Timestamps for better date handling

---

### **4. Denormalized Data**

**Collection:** `user_tickets`  
**Issue:** Event data (name, location, date) duplicated in each ticket
**Impact:** If event details change, tickets show outdated info  
**Recommendation:** This is acceptable for historical records (intentional denormalization)

---

## 🔍 DESIGN HEALTH ASSESSMENT

### **✅ Strengths**

1. **Modern Architecture:** Migrated from old `merchants`/`transactions` to `scan_points`/`interactions`
2. **Flexible Type System:** Polymorphic interactions support diverse campus activities
3. **Audit Trails:** Comprehensive logging via `logs` and `interactions`
4. **Event System:** Well-structured dual ticketing (user + guest)
5. **Library Workflow:** Two-step scanning process with session management

### **⚠️ Weaknesses**

1. **Incomplete Data:** Many expected collections empty (guest system, library loans, scanner sync)
2. **Inconsistent Fields:** User collection has partial field coverage
3. **Null Fields:** Book collection has unused fields
4. **String Dates:** Events use string dates instead of Timestamps

### **🚫 Critical Gaps**

1. **No Guest Usage:** Guest user/ticket system built but never tested
2. **No Library Loans:** Library catalog exists but no borrowing history
3. **No Scanner Sync:** Cross-device scanner infrastructure unused
4. **No Ticket Scans:** Verification system built but not utilized

---

## 📝 RECOMMENDATIONS

### **Immediate Actions**

1. **Fix User Field Inconsistency**

   ```javascript
   // Initialize missing fields with defaults
   await updateAllUsers({
     total_interactions: 0,
     active_tickets: 0,
     cancelled_tickets: 0,
     events_joined: 0,
   });
   ```

2. **Clean Up Book Schema**

   - Either populate `call_number`, `edition`, `subjects` or remove them
   - Add indexing on `availability` for faster queries

3. **Test Unused Systems**
   - Create test guest account to populate `guest_users`
   - Perform library borrow to populate `book_loans`
   - Trigger scanner sync to test `scanner_triggers`/`scanner_status`

### **Future Improvements**

1. **Add Compound Indexes**

   - `interactions`: (user_id, timestamp)
   - `user_tickets`: (user_id, status)
   - `events`: (is_active, date)

2. **Implement Data Validation Rules**

   - Required fields enforcement
   - Type validation via Firestore security rules

3. **Add Aggregation Collections**
   - User stats (derived from interactions)
   - Event attendance summaries
   - Revenue reports per scan point

---

## 📊 FINAL STATISTICS

| Metric                      | Value   |
| --------------------------- | ------- |
| **Total Collections**       | 15      |
| **Active Collections**      | 8 (53%) |
| **Empty Collections**       | 7 (47%) |
| **Total Documents**         | 84      |
| **Collections with Issues** | 4       |
| **Critical Issues**         | 0       |
| **Warnings**                | 6       |

---

## ✅ CONCLUSION

The Firestore database follows a **modern, well-designed architecture** with clear separation of concerns and polymorphic data models. However, **several features are built but never tested**, resulting in 7 empty collections.

**Current State:** Production-ready for core features (users, scan points, events, interactions)  
**Missing:** Guest mode, library loans, ticket verification, scanner sync are all **dormant**

**Next Steps:**

1. Fix user field inconsistencies
2. Test and activate guest mode
3. Perform library borrowing test
4. Clean up unused book fields

---

**Report Generated:** November 18, 2025  
**Inspection Mode:** READ-ONLY (No data modified)
