# Firebase Emulator Setup Guide

This guide covers setting up and running the Firebase emulators for local development of Prep Royale.

## Prerequisites

1. **Node.js 18** - Required for Cloud Functions
   ```bash
   node --version  # Should show v18.x.x
   ```

2. **Java 11+** - Required for Firestore and Realtime Database emulators
   ```bash
   java --version  # Should show 11.x.x or higher
   ```

3. **Firebase CLI** - Install globally
   ```bash
   npm install -g firebase-tools
   firebase --version  # Should show 13.x.x or higher
   ```

4. **Project Authentication**
   ```bash
   firebase login
   firebase use sat-act-battle-royale
   ```

## Starting the Emulators

### Quick Start (All Emulators)

```bash
# From project root
firebase emulators:start
```

### With Data Persistence (Recommended)

To preserve data between sessions:

```bash
firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data
```

### Functions Only (For Backend Development)

```bash
cd functions
npm run serve
```

This runs `npm run build && firebase emulators:start --only functions`.

## Emulator Ports

| Service           | Port  | URL                          |
|-------------------|-------|------------------------------|
| Auth              | 9099  | http://localhost:9099        |
| Firestore         | 8080  | http://localhost:8080        |
| Realtime Database | 9000  | http://localhost:9000        |
| Functions         | 5001  | http://localhost:5001        |
| Hosting           | 5000  | http://localhost:5000        |
| Emulator UI       | 4000  | http://localhost:4000        |

## Flutter Emulator Connection

The Flutter app automatically connects to emulators when running in debug mode. The configuration is in `lib/services/firebase_service.dart`:

```dart
// Emulator connection is configured in FirebaseService.init()
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  FirebaseDatabase.instance.useDatabaseEmulator('localhost', 9000);
}
```

### Android Emulator Note

When running on Android emulator, use `10.0.2.2` instead of `localhost`:

```dart
// For Android emulator
await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
```

### iOS Simulator Note

When running on iOS simulator, use `localhost` as shown above.

## Common Issues

### 1. Port Already in Use

**Error:** `Error: Could not start Firestore Emulator, port taken`

**Solution:** Kill the process using the port:
```bash
# Windows
netstat -ano | findstr :8080
taskkill /PID <pid> /F

# macOS/Linux
lsof -i :8080
kill -9 <pid>
```

Or specify different ports in `firebase.json`:
```json
{
  "emulators": {
    "firestore": { "port": 8081 }
  }
}
```

### 2. Java Not Found

**Error:** `Could not find java in PATH`

**Solution:**
1. Install Java 11+ from [Adoptium](https://adoptium.net/)
2. Add to PATH:
   - Windows: Add `JAVA_HOME\bin` to system PATH
   - macOS: `export PATH="/Library/Java/JavaVirtualMachines/adoptopenjdk-11.jdk/Contents/Home/bin:$PATH"`

### 3. Functions Not Updating

**Symptom:** Code changes not reflected in emulator

**Solution:**
1. Ensure TypeScript is compiling:
   ```bash
   cd functions
   npm run build:watch  # Keep this running in a separate terminal
   ```
2. The emulator auto-reloads when `lib/` changes

### 4. Cloud Functions Timeout

**Error:** `DEADLINE_EXCEEDED` or function hangs

**Solution:**
1. Check if you're calling production APIs (Vertex AI) from emulator
2. For Gemini/Vertex AI, you need real credentials even in emulator mode
3. Set `GOOGLE_APPLICATION_CREDENTIALS` environment variable:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"
   ```

### 5. Firestore Rules Not Applying

**Symptom:** Permissions work in emulator but fail in production

**Solution:**
1. Ensure `firestore.rules` is referenced in `firebase.json`
2. The emulator reloads rules automatically, but restart if issues persist

### 6. Authentication State Not Persisting

**Symptom:** User logged out after emulator restart

**Solution:** Use `--import/--export` flags to persist auth state:
```bash
firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data
```

## Recommended Development Workflow

1. **Terminal 1: TypeScript Watch Mode**
   ```bash
   cd functions
   npm run build:watch
   ```

2. **Terminal 2: Emulators with Persistence**
   ```bash
   firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data
   ```

3. **Terminal 3: Flutter App**
   ```bash
   flutter run
   ```

4. **Browser: Emulator UI**
   Open http://localhost:4000 to:
   - View/edit Firestore documents
   - View/edit Realtime Database
   - Manage Auth users
   - View function logs
   - Trigger Pub/Sub events

## Seeding Test Data

### Create Test User via Emulator UI

1. Go to http://localhost:4000/auth
2. Click "Add user"
3. Enter email/password

### Seed Questions via Cloud Function

```bash
# Trigger manual question generation
curl http://localhost:5001/sat-act-battle-royale/us-central1/manualGenerateQuestions \
  -H "Content-Type: application/json" \
  -d '{"data":{"examType":"SAT","section":"Math","skill":"LinearEquations","count":10}}'
```

### Seed via Emulator UI

1. Go to http://localhost:4000/firestore
2. Click "Start collection"
3. Add documents manually

## Cleaning Up

### Reset All Emulator Data

Simply don't use the `--import` flag:
```bash
firebase emulators:start
```

### Clear Specific Data

```bash
# Delete the export folder
rm -rf ./emulator-data

# Start fresh
firebase emulators:start --export-on-exit=./emulator-data
```

## Debugging Cloud Functions

### View Logs

Logs appear in the terminal running emulators, or in the Emulator UI under "Logs".

### Add Debug Logging

```typescript
import * as functions from "firebase-functions";

export const myFunction = functions.https.onCall((data, context) => {
  functions.logger.info("Debug info:", data);
  functions.logger.warn("Warning message");
  functions.logger.error("Error occurred:", error);
});
```

### Attach Debugger (VS Code)

1. Add to `.vscode/launch.json`:
   ```json
   {
     "type": "node",
     "request": "attach",
     "name": "Attach to Functions",
     "port": 9229,
     "restart": true
   }
   ```

2. Start emulator with inspect flag:
   ```bash
   firebase emulators:start --inspect-functions
   ```

3. Set breakpoints and attach debugger

## Environment Variables

For local development, create `functions/.env`:

```env
# Not needed for Vertex AI (uses project credentials)
# But useful for other services
SOME_API_KEY=your-key-here
```

Load in functions:
```typescript
import * as dotenv from "dotenv";
dotenv.config();
```

## Vertex AI / Gemini in Emulator

Gemini API calls go to the real Google Cloud even when running locally. To use Vertex AI:

1. Ensure you have a service account with Vertex AI permissions
2. Download the JSON key
3. Set the environment variable:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
   firebase emulators:start
   ```

Or set in `firebase.json`:
```json
{
  "emulators": {
    "functions": {
      "env": {
        "GOOGLE_APPLICATION_CREDENTIALS": "./service-account.json"
      }
    }
  }
}
```
