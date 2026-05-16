# Mobile Scanner Terminal System

## Overview

The Mobile Scanner Terminal is a dedicated mobile interface for merchant accounts that provides scanner functionality controlled by desktop triggers. This system ensures merchants on mobile devices have a streamlined, trigger-only scanner experience.

## Architecture

### 1. Mobile Scanner Terminal (`mobile_scanner_terminal.dart`)

- **Purpose**: Dedicated mobile interface for merchants
- **Features**:
  - Listens for desktop triggers targeting the same user account
  - Activates camera only when triggered from desktop
  - Provides simplified UI without access to normal user functions
  - Material Design 3 styling with responsive design

### 2. Login Routing (`login_page.dart`)

- **Merchant Mobile Routing**:
  - Desktop/macOS merchants → `Routes.merchantDashboard` (desktop interface)
  - Mobile merchants → `Routes.mobileScannerTerminal` (terminal interface)
  - Web merchants → Warning message (scanner disabled)

### 3. Desktop Trigger System (`merchant_dashboard_desktop.dart`)

- **Trigger Logic**:
  ```dart
  'triggered_by': uid,  // Merchant who triggered
  'target_uid': uid,    // Same merchant account on mobile
  'triggered_from': 'desktop'
  ```

### 4. Routes Configuration (`routes.dart`)

- Added `mobileScannerTerminal` route constant
- Integrated terminal page in `appRoutes` mapping

## Usage Flow

### Desktop → Mobile Trigger Flow:

1. **Desktop**: Merchant logs in → Desktop Dashboard → Trigger Scanner Tab
2. **Desktop**: Click "Open Mobile Scanner" → Writes trigger to Firestore
3. **Mobile**: Terminal receives trigger → Camera activates automatically
4. **Mobile**: Scanner reads QR codes → Ticket verification → Results display

### Security Features:

- **Same Account Targeting**: Desktop can only trigger mobile for same merchant account
- **Timestamp Validation**: Triggers expire after processing
- **Status Tracking**: Prevents duplicate processing of triggers
- **User Isolation**: Mobile terminal only accessible to merchants

## Files Modified/Created:

### New Files:

- `lib/pages_common/mobile_scanner_terminal.dart` - Terminal interface

### Modified Files:

- `lib/routes.dart` - Added terminal route and import
- `lib/pages_common/login_page.dart` - Updated merchant mobile routing
- `lib/pages_desktop/merchant_dashboard_desktop.dart` - Fixed trigger targeting

## Integration with Ticket Verification System:

The terminal integrates seamlessly with the existing ticket verification system:

- Uses `ScannerService` for ticket validation
- Displays `TicketVerificationDialog` for scan results
- Implements all security features (expiry, duplicates, merchant permissions)

## Technical Details:

### Real-time Listening:

```dart
FirebaseFirestore.instance
  .collection('scanner_triggers')
  .where('target_uid', isEqualTo: currentUserUid)
  .where('status', isEqualTo: 'pending')
  .snapshots()
```

### Camera Control:

- Camera only activates when trigger received
- Returns to waiting state after scan completion
- Handles camera permissions and errors gracefully

### Material Design 3 Compliance:

- Uses theme colors and components
- Responsive design for various screen sizes
- Accessible with proper semantic labels

## Testing Checklist:

- [ ] Desktop merchant can trigger mobile scanner
- [ ] Mobile merchant logs into terminal (not regular scanner)
- [ ] Camera activates only on desktop trigger
- [ ] Ticket verification works correctly
- [ ] Error handling displays appropriately
- [ ] Cross-device trigger system functions properly

## Future Enhancements:

- Multi-merchant support for business chains
- Trigger analytics and history
- Enhanced error reporting and diagnostics
- Offline ticket validation capabilities
