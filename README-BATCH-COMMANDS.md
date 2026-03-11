# Batch Command Reference

Quick reference for all batch scripts in this project.

## 🚀 Getting Started (First Time Setup)

### 1. **full-setup.bat**
Installs ALL dependencies and prepares the project.

```batch
full-setup.bat
```

**What it does:**
- ✅ Installs Firebase Functions dependencies (npm)
- ✅ Builds Cloud Functions (TypeScript → JavaScript)
- ✅ Installs Flutter dependencies
- ✅ Runs code generation (Riverpod/JSON)
- ✅ Runs Flutter Doctor health check

**When to use:** First time setting up the project, or after pulling major changes from git.

---

## 🔧 Development (Daily Use)

### 2. **start-emulators.bat**
Starts Firebase Emulators for local development.

```batch
start-emulators.bat
```

**What it does:**
- ✅ Installs/updates npm dependencies
- ✅ Builds Cloud Functions
- ✅ Starts all Firebase Emulators:
  - Auth Emulator (port 9099)
  - Firestore Emulator (port 8080)
  - Realtime Database Emulator (port 9000)
  - Functions Emulator (port 5001)
  - Emulator UI (port 4000)

**Emulator UI:** http://localhost:4000

**When to use:** ALWAYS run this BEFORE starting the Flutter app for development.

---

### 3. **start-app.bat**
Starts the Flutter app on a connected device/emulator.

```batch
start-app.bat
```

**What it does:**
- ✅ Checks Flutter installation
- ✅ Installs Flutter dependencies
- ✅ Runs code generation
- ✅ Lists available devices
- ✅ Starts Flutter app

**Prerequisites:** Firebase Emulators must be running (use `start-emulators.bat` first).

**When to use:** After starting emulators, run this to launch the app.

---

### 4. **generate-questions.bat**
Generates sample test questions in the emulator database.

```batch
generate-questions.bat
```

**What it does:**
- ✅ Adds 5 sample questions (SAT/ACT across various sections)
- ✅ Questions saved to Firestore Emulator

**Prerequisites:** Firebase Emulators must be running.

**When to use:** When you need test data in the emulator for development.

---

### 5. **watch-functions.bat**
Auto-rebuilds Cloud Functions when TypeScript files change.

```batch
watch-functions.bat
```

**What it does:**
- ✅ Monitors `functions/src/` folder
- ✅ Auto-compiles TypeScript to JavaScript on save
- ✅ Must restart emulators to reload functions

**When to use:** When actively developing Cloud Functions. Run in a separate terminal alongside emulators.

---

## 📦 Building & Deployment

### 6. **build-release.bat**
Builds a production-ready APK for Android.

```batch
build-release.bat
```

**What it does:**
- ✅ Installs dependencies
- ✅ Runs code generation
- ✅ Cleans previous builds
- ✅ Runs static analysis
- ✅ Builds release APK

**Output:** `build\app\outputs\flutter-apk\app-release.apk`

**When to use:** When ready to test/distribute the app outside of development.

---

### 7. **deploy-functions.bat**
Deploys Cloud Functions to PRODUCTION Firebase.

```batch
deploy-functions.bat
```

**What it does:**
- ✅ Builds Cloud Functions
- ✅ Deploys to production Firebase project
- ⚠️ **WARNING: This affects live users!**

**When to use:** When ready to push function changes to production. Use with caution!

---

## 📋 Typical Development Workflow

### Daily Development Session

**Terminal 1 - Start Emulators:**
```batch
start-emulators.bat
```
Leave this running. Emulator UI available at http://localhost:4000

**Terminal 2 - Start App:**
```batch
start-app.bat
```

**Terminal 3 (Optional) - Watch Functions:**
```batch
watch-functions.bat
```
Only if you're editing Cloud Functions.

---

### Need Test Data?

**Generate Sample Questions:**
```batch
generate-questions.bat
```
Run while emulators are running.

---

### Building for Release

**Create Production APK:**
```batch
build-release.bat
```
Find APK at: `build\app\outputs\flutter-apk\app-release.apk`

---

## 🛠️ Troubleshooting

### "Firebase Emulators not found"
Run `full-setup.bat` to ensure Firebase CLI is installed.

### "Flutter not found"
Install Flutter SDK: https://docs.flutter.dev/get-started/install

### App can't connect to emulators
1. Ensure `start-emulators.bat` is running
2. Check `firebase_config.dart` has `useEmulators = true`
3. Restart the app with `start-app.bat`

### Questions not showing in app
1. Run `generate-questions.bat` to add test questions
2. Check Firestore Emulator UI: http://localhost:4000/firestore
3. Look for `questions` collection

### Cloud Functions not working
1. Stop emulators (Ctrl+C)
2. Run `cd functions && npm run build`
3. Restart emulators with `start-emulators.bat`

---

## 🔄 After Pulling Code Updates

```batch
full-setup.bat
```

This reinstalls dependencies and rebuilds everything.

---

## 📝 Quick Reference Table

| Script | Use Case | Prerequisites |
|--------|----------|---------------|
| `full-setup.bat` | First-time setup / After git pull | None |
| `start-emulators.bat` | Start development environment | None |
| `start-app.bat` | Launch Flutter app | Emulators running |
| `generate-questions.bat` | Add test data | Emulators running |
| `watch-functions.bat` | Develop Cloud Functions | None |
| `build-release.bat` | Create production APK | None |
| `deploy-functions.bat` | Deploy to production | Firebase login |

---

## 🌐 Emulator URLs

When emulators are running:

- **Emulator UI:** http://localhost:4000
- **Firestore:** http://localhost:4000/firestore
- **Authentication:** http://localhost:4000/auth
- **Realtime Database:** http://localhost:4000/database
- **Functions Logs:** http://localhost:4000/logs

---

## 🔑 Environment Configuration

### Using Emulators (Default)
`lib/config/firebase_config.dart`:
```dart
static const bool useEmulators = true;
```

### Using Production Firebase
`lib/config/firebase_config.dart`:
```dart
static const bool useEmulators = false;
```
Then rebuild: `flutter run`

**⚠️ WARNING:** Don't commit production config with `useEmulators = false`!

---

## 💡 Pro Tips

1. **Keep emulators running** throughout your dev session
2. **Use watch-functions.bat** if editing Cloud Functions frequently
3. **Check Emulator UI** (http://localhost:4000) to inspect database state
4. **Generate questions** before testing Study/Battle modes
5. **Run full-setup.bat** after major git pulls
6. **Test release APK** on physical device before production deploy

---

## 📞 Need Help?

- Check Flutter console output for errors
- View emulator logs: http://localhost:4000/logs
- Review Cloud Functions logs: `cd functions && npm run logs`
- Check Flutter Doctor: `flutter doctor -v`

---

**Last Updated:** 2026-02-24
**Project:** SAT-ACT Battle Royale (Prep Royale)
