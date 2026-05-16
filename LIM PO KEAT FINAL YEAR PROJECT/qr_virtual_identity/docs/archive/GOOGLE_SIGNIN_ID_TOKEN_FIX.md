# Google Sign-In ID Token Fix Guide

## 🔴 Problem

You're getting: `Exception: Failed to obtain Google ID token`

This happens because the OAuth client is not properly configured in your Firebase project.

## 🔍 Root Cause

Your `android/app/google-services.json` has an **empty `oauth_client` array**:

```json
"oauth_client": [],  // ❌ Empty - this causes the ID token to be null
```

## ✅ Solution: Configure OAuth Client in Firebase Console

### Step 1: Enable Google Sign-In in Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **po-keat-fyp**
3. Navigate to **Authentication** → **Sign-in method**
4. Find **Google** in the providers list
5. Click **Enable** (if not already enabled)
6. Click **Save**

### Step 2: Add SHA-1 Fingerprint (Required for Android)

This is the **most important step** for Android Google Sign-In to work!

#### Get Your Debug SHA-1 Fingerprint:

**Option A: Using Gradle (Recommended)**

```powershell
cd android
./gradlew signingReport
```

Look for the **SHA-1** under **Variant: debug**. It looks like:

```
SHA1: A1:B2:C3:D4:E5:F6:G7:H8:I9:J0:K1:L2:M3:N4:O5:P6:Q7:R8:S9:T0
```

**Option B: Using keytool**

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### Add SHA-1 to Firebase:

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **Your apps** section
3. Find your Android app: `com.example.qr_virtual_identity`
4. Click **Add fingerprint**
5. Paste your SHA-1 fingerprint
6. Click **Save**

### Step 3: Download Updated google-services.json

1. In Firebase Console → **Project Settings** → **Your apps**
2. Click on your Android app
3. Click **Download google-services.json**
4. **Replace** the existing file:
   ```
   android/app/google-services.json
   ```
5. Verify the new file has the `oauth_client` section populated:
   ```json
   "oauth_client": [
     {
       "client_id": "XXXXX.apps.googleusercontent.com",
       "client_type": 3
     }
   ]
   ```

### Step 4: Clean and Rebuild

```powershell
cd c:\Users\ISAAC\.vscode\application\LIM PO KEAT FINAL YEAR PROJECT\qr_virtual_identity

# Clean Flutter build cache
flutter clean

# Get dependencies
flutter pub get

# Clean Android build
cd android
./gradlew clean
cd ..

# Rebuild and run
flutter run
```

## 🧪 Testing with Firebase Emulator

### Start Emulators

```powershell
firebase emulators:start
```

### Run the App

```powershell
flutter run
```

### Expected Console Output (Success):

```
🔐 Starting Google Sign-In flow...
👤 Google user selected: your.email@gmail.com
🔍 Access Token present: true
🔍 ID Token present: true
✅ Google ID token obtained successfully
✅ Firebase credential created with ID token
✅ Google Sign-In success: your.email@gmail.com
   UID: xxxxxxxxxxxxx
   Display Name: Your Name
```

### If ID Token is Still Null:

```
❌ ID Token is null - this usually means:
   1. OAuth client not configured in google-services.json
   2. SHA-1 fingerprint not added to Firebase Console
   3. Google Sign-In not enabled in Firebase Authentication
```

## 📝 Alternative: Quick Fix for Testing (Emulator Only)

If you just want to test other features and skip Google Sign-In for now, you can use email/password authentication which is already working in your app.

**Test Accounts:**

- Email: `student1@test.com`
- Password: `password123`

## 🌐 Web Platform Configuration

For Web builds, you need to configure the Web Client ID:

1. Firebase Console → **Authentication** → **Sign-in method** → **Google**
2. Copy the **Web client ID** (looks like: `XXXXX.apps.googleusercontent.com`)
3. Add to `index.html`:
   ```html
   <meta
     name="google-signin-client_id"
     content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com"
   />
   ```

## 🔧 Troubleshooting

### Issue: "Sign in failed" or "Error 10"

**Fix:** SHA-1 fingerprint not added to Firebase Console

### Issue: "API not enabled"

**Fix:** Enable Google Sign-In in Firebase Console → Authentication

### Issue: "Developer error"

**Fix:** Wrong package name in Firebase Console vs `android/app/build.gradle`

### Issue: Works on emulator but not real device

**Fix:** Add **release SHA-1** fingerprint to Firebase Console

## 📚 Current Configuration

**Project ID:** `po-keat-fyp`
**Package Name:** `com.example.qr_virtual_identity`
**Firebase Project Number:** `250324165347`

**Emulator Settings:**

- Auth Emulator: `localhost:9099`
- Firestore Emulator: `localhost:8080`

## 🎯 Next Steps After Configuration

1. ✅ Enable Google Sign-In in Firebase Console
2. ✅ Add SHA-1 fingerprint
3. ✅ Download updated google-services.json
4. ✅ Run `flutter clean && flutter pub get`
5. ✅ Test Google Sign-In

Once configured, the app will work with both Firebase Emulator and production Firebase without any code changes!
