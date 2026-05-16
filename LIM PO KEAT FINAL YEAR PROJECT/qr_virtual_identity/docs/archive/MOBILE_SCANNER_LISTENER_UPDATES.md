# Mobile Scanner Listener Updates

## 📝 Changes Made

### Updated Firestore Listener Logic

The mobile scanner listener in `lib/pages_common/mobile_scanner_terminal.dart` has been updated to support both direct triggers and broadcast triggers.

#### Before (OLD Logic):

```dart
// Only listened to direct triggers
.where('target_uid', isEqualTo: user.uid)
.where('status', isEqualTo: 'pending')
```

#### After (NEW Logic):

```dart
// Listen to ALL pending triggers, then filter manually
.where('status', isEqualTo: 'pending')
// Then filter: target_uid == user.uid OR target_uid == 'broadcast'
```

## 🎯 Supported Trigger Types

The mobile scanner now supports:

1. **Direct Triggers** → `target_uid: <merchant_uid>`
2. **Broadcast Triggers** → `target_uid: 'broadcast'`

## 🔧 Key Methods Updated

### 1. `_listenForTriggers()`

- Now listens to ALL pending documents
- Calls `_filterAndHandleTriggerSnapshot()` for filtering

### 2. `_filterAndHandleTriggerSnapshot()`

- **NEW METHOD** - Filters documents by target_uid
- Only accepts: `target_uid == user.uid` OR `target_uid == 'broadcast'`
- Logs filtering decisions for debugging

### 3. `_handleFilteredTriggerChanges()`

- **NEW METHOD** - Processes the filtered trigger changes
- Maintains all existing logic for documentChangeType.added
- Preserves timestamp validation (30-second window)

### 4. `_listenForStopCommands()`

- Updated to filter stop commands the same way
- Supports both direct and broadcast stop commands

## 🧹 Cleanup Tool

### `clear_scanner_triggers.dart`

- Utility script to clear old scanner_triggers documents
- Run before testing: `dart run clear_scanner_triggers.dart`

## 🔍 Debug Logging

Enhanced logging shows:

```
📡 [Mobile Terminal] Accepted trigger: target_uid=broadcast
📡 [Mobile Terminal] Accepted trigger: target_uid=<user_id>
📡 [Mobile Terminal] Filtered out trigger: target_uid=<other_id> (not for current user)
```

## ✅ Testing Checklist

1. **Clear old data**: `dart run clear_scanner_triggers.dart`
2. **Test direct triggers**: Desktop writes `target_uid: <merchant_uid>`
3. **Test broadcast triggers**: Desktop writes `target_uid: 'broadcast'`
4. **Test filtering**: Create trigger for different user (should be ignored)
5. **Test stop commands**: Both direct and broadcast stop commands
6. **Verify UI**: Scanner activation/deactivation still works properly

## 🚨 Important Notes

- **Backward Compatible**: Direct triggers still work exactly as before
- **No UI Changes**: All user-facing behavior remains the same
- **Performance**: Minimal impact - filtering happens in-memory
- **Debugging**: Enhanced logs help track filtering decisions
- **Error Handling**: All existing error handling preserved

## 🔧 Usage Examples

### Desktop Trigger (Direct)

```dart
await FirebaseFirestore.instance.collection('scanner_triggers').add({
  'target_uid': merchantUid,  // Direct to specific merchant
  'status': 'pending',
  'timestamp': FieldValue.serverTimestamp(),
});
```

### Desktop Trigger (Broadcast)

```dart
await FirebaseFirestore.instance.collection('scanner_triggers').add({
  'target_uid': 'broadcast',  // Broadcast to all merchants
  'status': 'pending',
  'timestamp': FieldValue.serverTimestamp(),
});
```

Both will trigger the mobile scanner for the logged-in merchant.
