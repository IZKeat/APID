# 🎓 Smart Campus Identity Hub - User Interface Upgrade

## 📋 Overview

This upgrade transforms the User (Student/Lecturer) interface into a comprehensive Smart Campus Identity Hub with analytics, interactive dashboards, and cross-module connectivity.

---

## 🏗️ Architecture

### New File Structure

```
lib/
├── theme/
│   └── app_theme.dart                    # Unified theme (Deep Purple + Amber)
├── services/
│   └── user_service.dart                  # Analytics & event management service
├── pages_user/
│   ├── user_functions_page.dart           # Enhanced functions with Campus Connect
│   ├── user_transactions_page.dart        # Smart transactions with filters
│   ├── user_activities_page.dart          # Unified event system
│   ├── user_profile_page.dart             # Smart profile with analytics
│   ├── user_insights_page.dart            # Data visualization page
│   └── widgets/
│       ├── adaptive_card.dart             # Reusable card component
│       ├── timeline_item.dart             # Activity timeline widget
│       ├── achievement_badge.dart         # Achievement display widget
│       └── chart_card.dart                # Analytics chart container
```

---

## 🎨 Design System

### Color Palette

- **Primary**: `#512DA8` (Deep Purple 700)
- **Accent**: `#FFA000` (Amber 700)
- **Background**: `#F9FAFB` (Light Gray)
- **Success**: `#4CAF50` (Green)
- **Error**: `#F44336` (Red)
- **Warning**: `#FF9800` (Orange)

### Typography

- **Font Family**: Inter (fallback to default)
- **Heading 1**: 28px, Bold
- **Heading 2**: 22px, Semibold
- **Heading 3**: 18px, Semibold
- **Body**: 14-16px, Regular

### Spacing & Radius

- **Spacing**: XS(4), SM(8), MD(16), LG(24), XL(32)
- **Border Radius**: SM(8), MD(12), LG(16), XL(20)
- **Elevation**: Low(2), Medium(4), High(8)

---

## 📄 Page Details

### 1️⃣ User Functions Page (`user_functions_page.dart`)

**Purpose**: Main action center for campus services

**Features**:

- Scan QR Code
- Show Personal QR
- **NEW**: Campus Connect (links to Activities)
- **NEW**: My Insights (links to analytics)

**Design**: 2x2 grid with gradient cards

---

### 2️⃣ Smart Transactions Page (`user_transactions_page.dart`)

**Purpose**: Aggregated transaction center with analytics

**Features**:

- **Header Section**:
  - This week's spending (highlighted card)
  - Average transaction value
  - Total activity count
- **Filter System**:
  - All, Purchase, Refund, Borrow, Return, Entry/Exit
- **Transaction Cards**:
  - Type-specific icons and colors
  - Timestamp with smart formatting
  - Status badges (success/pending/denied)
  - Amount display for commerce types

**Data Integration**:

- Firestore `interactions` collection
- Real-time updates via streams
- User-specific filtering by email

---

### 3️⃣ User Activities Page (`user_activities_page.dart`)

**Purpose**: Browse and join campus events

**Features**:

- **Two Tabs**:
  1. All Events (public events from Firestore)
  2. My Activities (joined events)
- **Event Cards**:
  - Image placeholder with category badge
  - Event details (date, time, location)
  - Capacity indicator
  - Join/Leave button
  - Tags display

**Integration**:

- Unified with Guest event system
- Uses same `events` collection
- User-specific registration in `user_events/{uid}/joined_events`

---

### 4️⃣ User Profile Page (`user_profile_page.dart`)

**Purpose**: Smart identity center with comprehensive analytics

**Sections**:

#### (a) Header - User Info

- Avatar with QR status badge (active/inactive)
- Name, email, role
- Last login timestamp
- Quick actions: Insights, Settings

#### (b) Smart Summary

Four metric cards:

- 💰 Total Spent
- 📚 Books Borrowed
- 🚪 Gate Accesses
- 📊 Total Interactions

#### (c) Activity Timeline

- Real-time stream of last 20 interactions
- Type-specific icons and colors
- Smart timestamp formatting (e.g., "2h ago")
- Amount display for purchases

#### (d) Achievements

- Auto-generated based on behavior
- Tier system: Bronze, Silver, Gold, Platinum
- Progress tracking
- Unlock conditions:
  - Campus Explorer: 10 interactions
  - Knowledge Seeker: 5 books borrowed
  - Campus Citizen: 20 interactions
  - APU Pioneer: 3 events joined

---

### 5️⃣ User Insights Page (`user_insights_page.dart`)

**Purpose**: Data visualization and analytics

**Charts**:

#### 1. Monthly Spending Trend (Line Chart)

- Last 6 months of purchase/refund data
- Interactive chart with fl_chart
- Gradient fill below line

#### 2. Most Visited Scan Points (Pie Chart)

- Top 5 locations
- Color-coded sections
- Legend with visit counts

#### 3. Quick Stats

- Average transaction value
- Total interactions
- Total spending

---

## 🔧 Service Layer

### `UserService` (`user_service.dart`)

#### Analytics Methods

**`getSmartSummary(String uid)`**

```dart
Returns: {
  'total_spent': double,
  'books_borrowed': int,
  'gate_accesses': int,
  'total_interactions': int,
}
```

Aggregates all successful interactions for the user.

**`getTimeline(String uid)` (Stream)**

```dart
Returns: Stream<List<Map<String, dynamic>>>
```

Real-time stream of last 20 interactions with full details.

**`getAchievements(String uid)`**

```dart
Returns: List<{
  'id': string,
  'title': string,
  'description': string,
  'tier': string,
  'unlocked': bool,
  'progress': int,
  'target': int,
}>
```

Calculates achievement progress based on user activity.

**`getMonthlySpending(String uid)`**

```dart
Returns: Map<String, double>  // {'2025-11': 45.50, ...}
```

Groups spending by month for chart visualization.

**`getScanPointsDistribution(String uid)`**

```dart
Returns: Map<String, int>  // {'Café': 12, 'Library': 8, ...}
```

Counts visits per scan point.

#### Event Management Methods

**`joinEvent({eventId, uid})`**

- Adds event to user's joined list
- Increments event attendee count
- Validates capacity

**`leaveEvent({eventId, uid})`**

- Removes event from joined list
- Decrements attendee count

**`hasJoinedEvent(uid, eventId)`**

- Checks registration status

**`getJoinedEventsStream(uid)` (Stream)**

- Real-time list of joined event IDs

---

## 🗄️ Firestore Schema

### Collections Used

#### `users`

```json
{
  "uid": "string",
  "email": "string",
  "first_name": "string",
  "last_name": "string",
  "role": "student" | "lecturer",
  "qr_status": "active" | "inactive",
  "total_spent": 0.0,
  "total_interactions": 0,
  "last_login": Timestamp
}
```

#### `interactions`

```json
{
  "interaction_id": "string",
  "user_email": "string",
  "user_id": "string",
  "scan_point_id": "string",
  "scan_point_name": "string",
  "type": "purchase" | "refund" | "borrow" | "return" | "entry" | "exit" | "attendance" | "booking",
  "status": "success" | "pending" | "denied",
  "remarks": "string",
  "timestamp": Timestamp,

  // Optional fields based on type
  "amount": double,           // for commerce
  "book_title": "string",     // for library
  "class_name": "string",     // for attendance
  "resource_name": "string"   // for booking
}
```

#### `events`

```json
{
  "event_id": "string",
  "name": "string",
  "description": "string",
  "category": "string",
  "location": "string",
  "date": "YYYY-MM-DD",
  "start_time": "HH:mm",
  "end_time": "HH:mm",
  "image_url": "string",
  "capacity": 100,
  "current_attendees": 45,
  "is_public": true,
  "is_active": true,
  "tags": ["tag1", "tag2"]
}
```

#### `user_events/{uid}/joined_events/{eventId}`

```json
{
  "event_id": "string",
  "joined_at": Timestamp,
  "status": "registered"
}
```

---

## 📦 Dependencies Added

```yaml
dependencies:
  # Existing
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  intl: ^0.19.0
  fl_chart: ^0.66.0

  # New additions
  shimmer: ^3.0.0
  cached_network_image: ^3.3.1
  provider: ^6.1.1
  firebase_storage: ^12.3.2
```

---

## 🎯 Key Features Summary

### ✅ What's Implemented

1. **Unified Theme System**

   - Consistent Deep Purple + Amber color scheme
   - Reusable widget components
   - Responsive design

2. **Smart Analytics**

   - Real-time data aggregation
   - Interactive charts (fl_chart)
   - Achievement system with progress tracking

3. **Enhanced User Experience**

   - Pull-to-refresh on all pages
   - Smart timestamp formatting
   - Loading states and error handling
   - Empty state placeholders

4. **Cross-Module Integration**

   - Shared event system with Guest mode
   - Unified interaction tracking
   - Consistent data models

5. **Modular Architecture**
   - Reusable widget library
   - Centralized service layer
   - Clean separation of concerns

---

## 🚀 Usage Examples

### Display User Summary

```dart
FutureBuilder<Map<String, dynamic>>(
  future: UserService.getSmartSummary(uid),
  builder: (context, snapshot) {
    final summary = snapshot.data!;
    return Text('Spent: RM ${summary['total_spent']}');
  },
)
```

### Stream Timeline

```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: UserService.getTimeline(uid),
  builder: (context, snapshot) {
    final timeline = snapshot.data!;
    return ListView(children: timeline.map(...));
  },
)
```

### Join Event

```dart
final result = await UserService.joinEvent(
  eventId: 'EVT001',
  uid: currentUserId,
);

if (result['success']) {
  // Show success message
}
```

---

## 🧪 Testing Checklist

- [x] All pages render without errors
- [x] Static analysis passes
- [x] Dependencies installed
- [x] Theme consistency verified
- [ ] Runtime testing on device/emulator
- [ ] Data fetching from Firestore
- [ ] Event join/leave functionality
- [ ] Chart rendering with real data
- [ ] Achievement calculation accuracy

---

## 🔜 Future Enhancements

1. **Profile Photo Upload**

   - Firebase Storage integration
   - Image picker and cropper

2. **Settings Page**

   - Notification preferences
   - Privacy controls
   - Account management

3. **Advanced Filters**

   - Date range selector
   - Multiple filter combination
   - Search functionality

4. **Export Features**

   - Download transaction history (PDF/CSV)
   - Share achievements
   - Generate reports

5. **Push Notifications**
   - Event reminders
   - Achievement unlocks
   - Transaction confirmations

---

## 📝 Notes

- All new pages use Firestore streams for real-time updates
- Achievements are calculated dynamically (not stored)
- Event capacity is enforced at join time
- Timezone handling uses device local time
- Images use cached_network_image for performance

---

## 👨‍💻 Developer Guide

### Adding New Achievement

1. Add condition to `UserService.getAchievements()`
2. Define tier (Bronze/Silver/Gold/Platinum)
3. Set unlock threshold
4. Achievement auto-appears in UI

### Creating Custom Chart

1. Extend `ChartCard` widget
2. Implement data fetching in `UserService`
3. Use fl_chart components
4. Add to Insights page

### Modifying Theme

1. Update `AppTheme` constants
2. Colors propagate automatically
3. Use helper methods for consistency

---

**Implementation Date**: November 5, 2025  
**Status**: ✅ Complete and Ready for Testing
