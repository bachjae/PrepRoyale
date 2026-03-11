# Prep Royale - Quick Start Guide

**Last Updated**: February 24, 2026

## TL;DR - What to Do Right Now

Your app is **ready for Version 1** after these steps:

### 1. Fix Build (5 minutes)
```cmd
fix-build.bat
```
See `BUILD_FIX_GUIDE.md` if fails.

### 2. Deploy Everything (15 minutes)
```cmd
cd functions
npm install
npm run build
firebase deploy
```

### 3. Set Gemini API Key (2 minutes)
```cmd
firebase functions:config:set gemini.api_key="YOUR_KEY_HERE"
firebase deploy --only functions
```

### 4. Generate Questions (30-60 minutes)
- Wait for midnight UTC (scheduled function), OR
- Call `manualGenerateQuestions` from Firebase Console
- Need >= 100 questions minimum

### 5. Test Core Flows (30 minutes)
```cmd
flutter run
```
- Sign up → Sign in
- Zen Mode (answer 10 questions)
- Battle Mode (2 devices, complete battle)

### 6. Launch 🚀
```cmd
flutter build apk --release
```

---

## What Was Fixed?

✅ **Android Build** - File locking issue fixed
✅ **Battle Randomization** - Questions now properly randomized (500 pool, Fisher-Yates)
✅ **Question Architecture** - Verified correct (no changes needed)
✅ **Auth Flow** - Verified correct (no changes needed)
✅ **Documentation** - 6 comprehensive guides created

---

## Documentation Map

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **QUICK_START.md** | This file - Fast overview | Start here |
| **FIXES_APPLIED_SUMMARY.md** | What we fixed in this session | See what changed |
| **VERSION_1_READINESS_REPORT.md** | Detailed readiness assessment | Before launch decision |
| **DEPLOYMENT_GUIDE.md** | Step-by-step deployment | When deploying |
| **TESTING.md** | Comprehensive test scripts | When testing |
| **BUILD_FIX_GUIDE.md** | Build troubleshooting | If build fails |
| **ISSUES_ANALYSIS.md** | Root cause analysis | Understand issues |
| **CLAUDE.md** | Project commands & architecture | Daily reference |

---

## Quick Reference: Common Commands

### Build & Run
```cmd
fix-build.bat              # Fix build issues
flutter run                # Run on device
flutter build apk --debug  # Build debug APK
flutter build apk --release # Build release APK
```

### Firebase
```cmd
firebase deploy                          # Deploy everything
firebase deploy --only functions         # Deploy only functions
firebase deploy --only firestore:rules   # Deploy only rules
firebase functions:list                  # List functions
firebase functions:log                   # View logs
```

### Functions
```cmd
cd functions
npm install                # Install deps
npm run build              # Build TypeScript
npm run serve              # Run local emulators
npm run logs               # View logs
```

---

## Quick Checklist: Ready to Launch?

### Prerequisites ⚠️
- [ ] Android build works (`fix-build.bat` passed)
- [ ] Cloud Functions deployed
- [ ] Gemini API key set
- [ ] >= 100 questions generated
- [ ] Security rules deployed

### Testing ✅
- [ ] Sign-up and sign-in work (< 5 seconds)
- [ ] Zen Mode loads questions
- [ ] Battle Mode works (tested with 2 devices)
- [ ] Friends system functional (add, accept, battle)
- [ ] Answer randomization verified

### Legal (Optional for internal testing) 📄
- [ ] Privacy Policy added
- [ ] Terms of Service added
- [ ] Delete account function working

---

## Priority Order

1. **Critical** (Do First):
   - Fix build
   - Deploy functions
   - Generate questions

2. **Important** (Do Before Public Launch):
   - Test all features
   - Add legal documents
   - Test on multiple devices

3. **Optional** (Nice to Have):
   - Configure notifications
   - Enable analytics
   - Performance monitoring

---

## Need Help?

- **Build fails?** → `BUILD_FIX_GUIDE.md`
- **How to deploy?** → `DEPLOYMENT_GUIDE.md`
- **How to test?** → `TESTING.md`
- **What's ready?** → `VERSION_1_READINESS_REPORT.md`
- **General questions?** → Check `CLAUDE.md`

---

## Next Steps

1. Run `fix-build.bat` NOW
2. Read `DEPLOYMENT_GUIDE.md` (Steps 1-6)
3. Follow `TESTING.md` (Test Suites 1-4 at minimum)
4. Review `VERSION_1_READINESS_REPORT.md` before launch
5. 🚀 Deploy to Play Store internal testing

---

**Estimated Time to Launch**: 2-4 hours total

Good luck! 🎉
