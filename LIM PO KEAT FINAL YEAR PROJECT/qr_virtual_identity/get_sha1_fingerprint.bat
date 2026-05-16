# get_sha1_fingerprint.bat
@echo off
echo ========================================
echo   Getting Android Debug SHA-1 Fingerprint
echo ========================================
echo.

echo Method 1: Using Gradle (Recommended)
echo -------------------------------------
cd android
call gradlew.bat signingReport
cd ..
echo.
echo.

echo Method 2: Using keytool
echo -------------------------------------
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
echo.
echo.

echo ========================================
echo INSTRUCTIONS:
echo 1. Copy the SHA-1 fingerprint from above
echo    (looks like: A1:B2:C3:D4:... with colons)
echo.
echo 2. Go to Firebase Console:
echo    https://console.firebase.google.com/
echo.
echo 3. Select project: po-keat-fyp
echo.
echo 4. Click Settings gear icon
echo.
echo 5. Scroll to "Your apps" section
echo.
echo 6. Find Android app: com.example.qr_virtual_identity
echo.
echo 7. Click "Add fingerprint"
echo.
echo 8. Paste your SHA-1
echo.
echo 9. Click Save
echo.
echo 10. Download new google-services.json
echo.
echo 11. Replace android/app/google-services.json
echo ========================================
pause
