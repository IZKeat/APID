# 🔑 IMMEDIATE ACTION REQUIRED: Add SHA-1 to Firebase Console

## Your SHA-1 Fingerprint (Debug Keystore)

```
93:6B:7C:8D:1C:2D:11:CC:D8:37:D9:FD:6C:C6:90:0E:A5:B8:91:2E
```

## 📋 Step-by-Step Instructions

### Step 1: Go to Firebase Console

1. Open: https://console.firebase.google.com/
2. Select project: **po-keat-fyp**

### Step 2: Open Project Settings

1. Click the **Settings gear icon** (⚙️) in the left sidebar
2. Select **Project settings**

### Step 3: Find Your Android App

1. Scroll down to **Your apps** section
2. Find the Android app with package name:
   ```
   com.example.qr_virtual_identity
   ```

### Step 4: Add SHA-1 Fingerprint

1. Click **Add fingerprint** button
2. Paste this SHA-1:
   ```
   93:6B:7C:8D:1C:2D:11:CC:D8:37:D9:FD:6C:C6:90:0E:A5:B8:91:2E
   ```
3. Click **Save**

### Step 5: Enable Google Sign-In (If Not Already Enabled)

1. In Firebase Console, go to **Authentication** (in left sidebar)
2. Click **Sign-in method** tab
3. Find **Google** in the providers list
4. If not enabled:
   - Click on **Google**
   - Toggle **Enable**
   - Enter your support email
   - Click **Save**

### Step 6: Download Updated google-services.json

1. Go back to **Project Settings** → **Your apps**
2. Find your Android app
3. Click **Download google-services.json** button
4. **Replace** the existing file at:
   ```
   c:\Users\ISAAC\.vscode\application\LIM PO KEAT FINAL YEAR PROJECT\qr_virtual_identity\android\app\google-services.json
   ```

### Step 7: Verify the New google-services.json

Open the new file and verify it has the `oauth_client` section populated:

```json
"oauth_client": [
  {
    "client_id": "XXXXX-XXXXX.apps.googleusercontent.com",
    "client_type": 3
  }
],
```

If you see this, you're good! ✅

### Step 8: Clean and Rebuild

Run these commands in PowerShell:

```powershell
cd "c:\Users\ISAAC\.vscode\application\LIM PO KEAT FINAL YEAR PROJECT\qr_virtual_identity"

# Clean everything
flutter clean
flutter pub get

# Clean Android build
cd android
.\gradlew.bat clean
cd ..

# Rebuild
flutter run
```

## 🧪 Test Google Sign-In

### 1. Start Firebase Emulators

```powershell
firebase emulators:start
```

### 2. Run the App

```powershell
flutter run
```

### 3. Try Google Sign-In

Click "Sign in with Google" and watch the console output.

**Expected Success Output:**

```
🔐 Starting Google Sign-In flow...
👤 Google user selected: your.email@gmail.com
🔍 Access Token present: true
🔍 ID Token present: true    <-- This should now be true!
✅ Google ID token obtained successfully
✅ Firebase credential created with ID token
✅ Google Sign-In success: your.email@gmail.com
   UID: xxxxxxxxxxxxx
   Display Name: Your Name
```

**If Still Failing:**

```
❌ ID Token is null - this usually means:
   1. OAuth client not configured in google-services.json
   2. SHA-1 fingerprint not added to Firebase Console  <-- Check this!
   3. Google Sign-In not enabled in Firebase Authentication
```

## ⚠️ Important Notes

1. **After adding SHA-1, you MUST download new google-services.json**

   - The old file won't magically update
   - Firebase generates OAuth credentials based on the SHA-1

2. **Each keystore needs its own SHA-1**

   - Debug keystore: `93:6B:7C:8D:1C:2D:11:CC:D8:37:D9:FD:6C:C6:90:0E:A5:B8:91:2E`
   - Release keystore: (add when deploying to production)

3. **Changes take effect immediately**
   - No need to wait
   - Just rebuild and run

## 🔍 Troubleshooting

### "Sign in failed" or "Error 10"

- SHA-1 not added correctly
- Wrong package name
- Solution: Double-check SHA-1 in Firebase Console

### "API not enabled"

- Google Sign-In not enabled in Authentication
- Solution: Enable in Firebase Console → Authentication → Sign-in method

### "Developer error"

- Package name mismatch
- Solution: Verify package name matches `com.example.qr_virtual_identity`

### ID Token still null after all steps

- Make sure you downloaded the NEW google-services.json AFTER adding SHA-1
- Run `flutter clean` and rebuild

## 📞 Need Help?

If you've followed all steps and it still doesn't work:

1. Check the downloaded google-services.json has `oauth_client` filled
2. Verify SHA-1 is visible in Firebase Console under your app
3. Make sure Google Sign-In is enabled in Authentication
4. Try `flutter clean && flutter pub get` again

---

**Your Project Info:**

- Package: `com.example.qr_virtual_identity`
- Project ID: `po-keat-fyp`
- Debug SHA-1: `93:6B:7C:8D:1C:2D:11:CC:D8:37:D9:FD:6C:C6:90:0E:A5:B8:91:2E`
