# 👤 Guest Profile & Achievement System

## 📋 Overview

Extended Guest Mode with a **Bottom Navigation** layout, **Profile Page**, and **Points & Achievement System**. Guests can now track their progress, view joined events, and earn tier badges.

---

## 🎯 Key Features

### 1️⃣ **Bottom Navigation Bar**

- **3 Tabs**:
  - 🏠 **Home** → Browse public events
  - 🎟️ **My Tickets** → View joined event tickets
  - 👤 **Profile** → Personal info, achievements, and stats
- **Persistent Navigation**: IndexedStack maintains page state
- **Material 3 Design**: Deep Purple + Amber color scheme

### 2️⃣ **Guest Profile Page**

The profile page displays:

- **User Info Header**:

  - Google profile photo (CircleAvatar)
  - Display name
  - Email address
  - Guest ID (truncated UID)
  - Join date

- **Achievements & Points**:

  - **Points System**: 10 points per joined event
  - **Tier Badges**:
    - 🥉 **Bronze** (0-30 points / 1-3 events)
    - 🥈 **Silver** (40-60 points / 4-6 events)
    - 🥇 **Gold** (70+ points / 7+ events)
  - Progress bar to next tier
  - Event count statistics

- **My Tickets Section**:

  - Horizontally scrollable cards
  - Shows last 3 active tickets
  - Quick QR view access
  - Status badges (Active / Verified)

- **Logout Button**:
  - Confirmation dialog
  - Signs out and returns to login page

### 3️⃣ **Points & Achievement System**

**Automatic Point Updates**:

- Points awarded when joining events (10 pts each)
- Points recalculated when canceling events
- Tier automatically updated based on points

**Achievement Levels**:
| Tier | Points Range | Events Joined | Badge Icon |
|--------|--------------|---------------|-------------------|
| Bronze | 0 - 30 | 1 - 3 | 🥉 Premium badge |
| Silver | 40 - 60 | 4 - 6 | 🥈 Military medal |
| Gold | 70+ | 7+ | 🥇 Trophy |

---

## 📂 Files Created / Modified

### **New Files**:

1. **`lib/pages_guest/guest_profile_page.dart`**

   - Profile UI with user info, achievements, tickets
   - Fetches data from Firestore and FirebaseAuth
   - Pull-to-refresh support
   - Logout functionality

2. **`lib/pages_guest/guest_main_nav.dart`**

   - Bottom navigation controller
   - 3 tabs: Events, My Tickets, Profile
   - IndexedStack for state preservation

3. **`GUEST_PROFILE_README.md`** (this file)
   - Documentation for Guest Profile system

### **Modified Files**:

1. **`lib/services/guest_service.dart`**

   - Added `updateGuestPoints(uid)` - Calculates points and tier
   - Added `getGuestAchievements(uid)` - Returns achievement data
   - Added `getRecentJoinedEvents(uid)` - Fetches recent events
   - Updated `joinEvent()` - Auto-updates points after joining
   - Updated `cancelRegistration()` - Recalculates points after canceling
   - Updated `createOrUpdateGuestUser()` - Initializes `points: 0` and `tier: 'Bronze'`

2. **`lib/routes.dart`**

   - Added route: `Routes.guestMainNav` → `/guest/main`
   - Added route: `Routes.guestProfile` → `/guest/profile`
   - Updated route map with new pages

3. **`lib/pages/login_page.dart`**
   - Changed navigation target from `Routes.guestEvents` → `Routes.guestMainNav`
   - Guests now land on bottom navigation instead of events page directly

---

## 🔥 Firestore Schema Changes

### **`guest_users` Collection**

```json
{
  "uid": "google_uid_abc123",
  "name": "John Doe",
  "email": "john@gmail.com",
  "photo_url": "https://lh3.googleusercontent.com/...",
  "role": "guest",
  "joined_events": ["EVT001", "EVT002", "EVT003"],
  "points": 30,          // ✅ NEW: Auto-calculated (10 pts per event)
  "tier": "Bronze",      // ✅ NEW: Bronze / Silver / Gold
  "created_at": Timestamp,
  "last_login": Timestamp,
  "updated_at": Timestamp // ✅ NEW: Updated when points change
}
```

**No changes to `guest_tickets` or `events` collections.**

---

## 🧪 Testing Checklist

### ✅ **Login Flow**

- [x] Google Sign-In redirects to Bottom Navigation
- [x] User lands on "Home" tab (Events page)
- [x] Profile tab shows correct user info

### ✅ **Points & Achievements**

- [x] New users start with 0 points, Bronze tier
- [x] Joining an event awards 10 points
- [x] Tier updates correctly:
  - 1 event → Bronze (10 pts)
  - 4 events → Silver (40 pts)
  - 7 events → Gold (70 pts)
- [x] Canceling an event reduces points

### ✅ **Profile Page**

- [x] Shows user photo, name, email
- [x] Displays correct points and tier badge
- [x] Progress bar shows % to next tier
- [x] "My Tickets" section shows last 3 tickets
- [x] Tickets are horizontally scrollable
- [x] Tapping ticket opens QR view
- [x] Logout button works (shows confirmation)

### ✅ **Bottom Navigation**

- [x] 3 tabs visible and clickable
- [x] Active tab highlighted in Amber
- [x] IndexedStack preserves page state
- [x] Navigation icons correct:
  - Home: `event_available`
  - My Tickets: `confirmation_num_outlined`
  - Profile: `person_outline`

---

## 🎨 UI/UX Design

### **Color Palette**

- **Primary**: `#512DA8` (Deep Purple)
- **Accent**: `#FFA000` (Amber)
- **Success**: Green (`verified` tickets)
- **Tier Colors**:
  - Bronze: Brown
  - Silver: Gray
  - Gold: Amber (#FFA000)

### **Typography**

- **Profile Name**: `headlineSmall` (bold, Deep Purple)
- **Section Titles**: `titleLarge` (bold, Deep Purple)
- **Body Text**: `bodyMedium` (gray)
- **Stats**: Large bold numbers with colored icons

### **Components**

- **Cards**: Elevation 2, rounded corners
- **Badges**: Rounded containers with border and icon
- **Progress Bar**: 12px height, rounded, colored by tier
- **Tickets**: Gradient background (Deep Purple → Light Purple)

---

## 🚀 Usage Instructions

### **For Developers**

1. **Run the app**:

   ```bash
   flutter pub get
   flutter run -d <device>
   ```

2. **Seed events** (desktop only):

   - Open app on Windows/macOS/Linux
   - Events seeded automatically (`seed_service.dart`)

3. **Test on mobile**:

   - Use Google Sign-In on Android/iOS
   - Browse events → Join → Check profile

4. **Test points system**:
   ```dart
   // Join multiple events to test tier progression:
   // 1 event → Bronze (10 pts)
   // 4 events → Silver (40 pts)
   // 7 events → Gold (70 pts)
   ```

### **For Users**

1. **Login**: Tap "Continue as Guest (Google)" on mobile
2. **Browse Events**: View public events on Home tab
3. **Join Event**: Tap event → Join → Get ticket
4. **View Profile**: Tap Profile tab to see:
   - Your info
   - Points and tier badge
   - Recent tickets
   - Achievement progress
5. **Check Tickets**: My Tickets tab shows all joined events
6. **Logout**: Profile → Logout button

---

## 📊 Points Calculation Logic

```dart
// Example calculations:
final eventsJoined = 5;
final points = eventsJoined * 10; // 50 points

String tier;
if (points >= 70) tier = 'Gold';
else if (points >= 40) tier = 'Silver';
else tier = 'Bronze';

// Result: 50 points → Silver tier
```

**Progress to Next Tier**:

- **Bronze → Silver**: Need 40 points (4 events)
- **Silver → Gold**: Need 70 points (7 events)
- **Gold**: Max tier (progress bar = 100%)

---

## 🔧 Technical Implementation

### **State Management**

- Uses `StatefulWidget` with local state
- `StreamBuilder` for real-time ticket updates
- `FutureBuilder` for one-time data fetching
- Pull-to-refresh with `RefreshIndicator`

### **Navigation**

- `GuestMainNav` uses `IndexedStack` (preserves state)
- `BottomNavigationBar` controls active tab
- Route guards ensure guests stay in guest flow

### **Data Flow**

```
User joins event
    ↓
GuestService.joinEvent()
    ↓
Add ticket to Firestore
    ↓
Update joined_events array
    ↓
GuestService.updateGuestPoints()
    ↓
Calculate points (events * 10)
    ↓
Determine tier (Bronze/Silver/Gold)
    ↓
Update Firestore (points, tier, updated_at)
    ↓
Profile page auto-refreshes (StreamBuilder)
```

### **Error Handling**

- Try-catch blocks in all async operations
- Null checks for user authentication
- Default values for missing Firestore fields
- Print statements for debugging

---

## 🐛 Known Issues & Limitations

1. **Firestore Emulator**:

   - Auth Emulator disabled for Google Sign-In support
   - Firestore Emulator still active for student/admin data
   - Guest data uses production Firestore

2. **Points System**:

   - Points only update on join/cancel, not on verification
   - No negative points (minimum = 0)
   - No bonus points for special events (future enhancement)

3. **Profile Page**:
   - Recent tickets limited to 3 (horizontal scroll)
   - No edit profile functionality
   - Can't change profile photo (uses Google photo only)

---

## 🔮 Future Enhancements

### **Possible Features**:

- 🏆 **Custom Achievements**: "First Event", "Weekend Warrior", "Tech Enthusiast"
- 🎁 **Rewards System**: Redeem points for prizes
- 📊 **Analytics Dashboard**: Event attendance stats
- 🔔 **Push Notifications**: Event reminders
- 🌐 **Social Sharing**: Share achievements on social media
- 📅 **Calendar Integration**: Add events to Google Calendar
- ⭐ **Event Ratings**: Rate attended events
- 🎨 **Theme Customization**: Dark mode support

### **Technical Improvements**:

- State management with Riverpod/Bloc
- Offline support with local caching
- Image optimization and lazy loading
- Accessibility improvements (screen reader support)
- Unit tests and widget tests
- Integration tests for full user flows

---

## 📞 Support & Contact

For issues, questions, or feature requests:

- **Project**: QR Virtual Identity System
- **Module**: Guest Mode - Profile & Achievements
- **Last Updated**: November 2025

---

## ✅ Verification Commands

```bash
# Check file structure
ls lib/pages_guest/

# Expected files:
# - guest_main_nav.dart
# - guest_profile_page.dart
# - guest_events_page.dart
# - guest_event_detail_page.dart
# - guest_my_tickets_page.dart
# - guest_ticket_page.dart

# Run static analysis
flutter analyze

# Run app on device
flutter run -d <device_id>

# Clean and rebuild (if issues)
flutter clean
flutter pub get
flutter run
```

---

## 🎉 Success Metrics

**Implementation Complete When**:

- ✅ Bottom navigation works on all 3 tabs
- ✅ Profile page displays user info correctly
- ✅ Points update automatically on join/cancel
- ✅ Tier badges show correct icon and color
- ✅ Progress bar animates to next tier
- ✅ My Tickets section shows recent tickets
- ✅ Logout button signs out and redirects
- ✅ No compile errors or warnings
- ✅ App runs smoothly on Android/iOS

**All criteria met!** 🚀
