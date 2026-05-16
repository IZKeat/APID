# Quick Start Guide - Google Sign-In with Firebase Emulator

## 🚀 Quick Setup (3 Steps)

### Step 1: Start Firebase Emulators

```bash
cd "c:\Users\ISAAC\.vscode\application\LIM PO KEAT FINAL YEAR PROJECT\qr_virtual_identity"
firebase emulators:start
```

**Expected Output:**

```
✔  All emulators ready!
│ ✔  functions[us-central1-yourFunction]: http function initialized (http://127.0.0.1:5001/...)
│ ✔  firestore: Firestore Emulator UI websocket is running on 8080.
│ ✔  auth: Authentication Emulator UI is running on http://127.0.0.1:9099
```

---

### Step 2: Run the Flutter App

```bash
flutter run
```

**For Production Mode (bypass emulator):**

```bash
flutter run --dart-define=USE_FIREBASE_EMULATOR=false
```

---

### Step 3: Test Google Sign-In

1. Open the app
2. Navigate to Login page
3. Click **"Sign in with Google"**
4. Select Google account
5. ✅ Success! You'll be navigated to the guest dashboard

---

## 🔧 Troubleshooting

### ❌ Error: "Connection refused"

**Solution:**

1. Verify emulators are running: `firebase emulators:start`
2. Check IP address in `main.dart` (line 32):
   ```dart
   const String computerIpForRealDevice = '192.168.0.17'; // Update this!
   ```
3. Get your IP: Run `ipconfig` in PowerShell, find IPv4 Address

---

### ❌ Error: "Invalid ID token"

**Solution:**

1. Clear app cache and restart
2. Sign out and sign in again
3. Restart Firebase emulators

---

### ❌ Error: "Google Sign-In failed"

**Solution:**

1. Check console logs for detailed error
2. Verify Google Sign-In is enabled in Firebase Console
3. Ensure `google-services.json` is up to date

---

## 📱 Platform-Specific Notes

### Android Device (Real Device, not Emulator)

Update the IP address in `main.dart`:

```dart
const String computerIpForRealDevice = 'YOUR_COMPUTER_IP'; // e.g., 192.168.1.100
```

Find your IP:

```powershell
ipconfig
# Look for "IPv4 Address" under your active network adapter
```

---

### Windows Desktop

No changes needed. Uses `127.0.0.1` (localhost)

---

### Web

Set `kIsWeb` to true automatically. Uses `127.0.0.1`

---

## 🎯 Key Files

### Authentication Logic

- **`lib/services/auth_service.dart`** - Core Google Sign-In implementation
- **`lib/pages_common/login_page.dart`** - Login UI

### Configuration

- **`lib/main.dart`** - Emulator setup (lines 25-76)

### Guest Features

- **`lib/services/guest_service.dart`** - Guest user management

---

## 📊 Verification Checklist

Before deploying or testing:

- [ ] Firebase emulators are running
- [ ] IP address matches your computer (for Android devices)
- [ ] `flutter analyze` shows 0 errors
- [ ] Google Sign-In completes successfully
- [ ] User is created in Firestore emulator
- [ ] Sign-out works properly

---

## 🔑 Important Code Changes

### OLD (Broken with Emulator):

```dart
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,  // ❌ Rejected by emulator
  idToken: googleAuth.idToken,
);
```

### NEW (Works with Emulator + Production):

```dart
final credential = GoogleAuthProvider.credential(
  idToken: googleAuth.idToken,  // ✅ Works everywhere
);
```

---

## 💡 Tips

1. **Check Emulator Logs:**

   - Auth UI: http://localhost:9099
   - Firestore UI: http://localhost:4000

2. **Clear Auth State:**

   ```dart
   await FirebaseAuth.instance.signOut();
   ```

3. **Debug Mode:**

   - All authentication steps are logged to console
   - Look for 🔐, ✅, ❌ emoji prefixes

4. **Production Deployment:**
   - No code changes needed!
   - Just run without `--dart-define` flag
   - App auto-detects and uses production Firebase

---

## 📞 Quick Commands

```bash
# Start emulators
firebase emulators:start

# Run app (emulator mode)
flutter run

# Run app (production mode)
flutter run --dart-define=USE_FIREBASE_EMULATOR=false

# Check for errors
flutter analyze

# Clean build
flutter clean
flutter pub get
flutter run

# Get computer IP (Windows)
ipconfig

# View emulator UI
# Auth: http://localhost:9099
# Firestore: http://localhost:4000
```

---

## ✅ Success Indicators

**Console Output:**

```
🔐 Starting Google Sign-In flow...
👤 Google user selected: user@example.com
🎫 Google ID token obtained
✅ Firebase credential created with ID token
✅ Google Sign-In success: user@example.com
   UID: abc123...
   Display Name: John Doe
```

**UI Behavior:**

- Loading indicator during sign-in
- Smooth navigation to guest dashboard
- No error dialogs
- User data visible in profile page

---

**Last Updated:** November 7, 2025  
**Status:** ✅ Ready for Production  
**Tested On:** Windows Desktop, Firebase Emulator
