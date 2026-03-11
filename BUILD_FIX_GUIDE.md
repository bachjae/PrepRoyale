# Android Build Fix Guide

## Problem
`Task :app:mergeLibDexDebug` fails with:
```
java.io.IOException: Unable to delete directory ... Failed to delete some children.
```

## Root Cause
File locking on Windows caused by:
1. **OneDrive** syncing the build directory
2. **Antivirus** scanning build artifacts
3. **Gradle daemon** holding file handles
4. **IDE processes** indexing files

## Solution

### Option 1: Automated Fix Script (Recommended)
1. **Close all IDEs** (VS Code, Android Studio, etc.)
2. Run `fix-build.bat`
3. If it fails with file locking errors, proceed to Option 2

### Option 2: Manual Steps

#### Step 1: Pause OneDrive Sync
1. Right-click OneDrive icon in system tray
2. Click "Pause sync" → "2 hours"
3. OR: Move project out of OneDrive folder temporarily

#### Step 2: Stop All Processes
```cmd
cd android
gradlew.bat --stop
cd ..
```

#### Step 3: Close IDEs
- Close VS Code
- Close Android Studio
- Close any file explorers viewing the project

#### Step 4: Clean Everything
```cmd
flutter clean
rmdir /s /q build
rmdir /s /q android\.gradle
rmdir /s /q .dart_tool
```

Wait 5 seconds for file system to release locks.

#### Step 5: Rebuild
```cmd
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --debug
```

#### Step 6: Test Run
```cmd
flutter run
```

### Option 3: Permanent Fix (Move Out of OneDrive)

The **safest long-term solution** is to move the project outside of OneDrive:

1. Move project to `C:\Projects\SAT-ACT-Battle-Royale`
2. Update Firebase CLI config if needed
3. Resume OneDrive sync

## Prevention

### Gradle Properties Updated
The following settings were added to `android/gradle.properties`:
- `org.gradle.vfs.watch=false` - Disables file system watching (prevents locks)
- `org.gradle.caching=true` - Speeds up builds
- `org.gradle.parallel=true` - Parallel execution
- `org.gradle.daemon=true` - Keeps daemon alive

### .gitignore Verification
Ensure these are in `.gitignore`:
```
build/
.dart_tool/
.gradle/
*.iml
```

## Verification Commands

After fixing, verify build works:
```cmd
# 1. Clean build
flutter clean && flutter pub get

# 2. Test debug build
flutter build apk --debug

# 3. Test run on device/emulator
flutter run

# 4. Test release build (optional)
flutter build apk --release
```

## Common Errors After Fix

### "Execution failed for task ':app:checkDebugDuplicateClasses'"
- Run: `flutter clean && flutter pub get`
- Delete `android/build` folder manually

### "Could not resolve all files for configuration"
- Check internet connection
- Run: `cd android && gradlew.bat --refresh-dependencies`

### "Manifest merger failed"
- Check `android/app/src/main/AndroidManifest.xml`
- Ensure all Firebase services have required permissions

## Success Indicators

✅ Build completes without "Unable to delete directory" errors
✅ `flutter run` starts the app on device/emulator
✅ Hot reload works without rebuild
✅ No file locking warnings in console

## If Still Failing

1. **Disable antivirus temporarily** (add project folder to exclusions)
2. **Reboot Windows** (releases all file handles)
3. **Use PowerShell as admin** to force delete:
   ```powershell
   Remove-Item -Recurse -Force build
   Remove-Item -Recurse -Force android\.gradle
   Remove-Item -Recurse -Force .dart_tool
   ```
4. **Check for background processes**:
   ```cmd
   tasklist | findstr "dart flutter gradle java"
   ```
