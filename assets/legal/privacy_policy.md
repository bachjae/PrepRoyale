# Privacy Policy

**Last Updated: February 21, 2026**

## Introduction

Welcome to Prep Royale ("we," "our," or "the App"). This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy, please do not access the application.

We reserve the right to make changes to this Privacy Policy at any time and for any reason. We will alert you about any changes by updating the "Last Updated" date of this Privacy Policy. You are encouraged to periodically review this Privacy Policy to stay informed of updates.

This Privacy Policy applies to information we collect through the Prep Royale mobile application and services provided therein.

## Governing Law

This Privacy Policy is governed by and construed in accordance with the laws of the State of Nebraska, United States, without regard to its conflict of law provisions. By using this App, you consent to the jurisdiction of the state and federal courts located in Nebraska for any disputes arising from or relating to your use of the App or this Privacy Policy.

## Information We Collect

### 1. Personal Information You Provide

When you register for an account, we collect the following personal information:

**Account Registration Information:**
- Email address (required for email/password authentication)
- Username (publicly visible, used for identification in-app)
- Password (encrypted and stored securely by Firebase Authentication)
- Profile picture (optional, either selected from preset avatars or uploaded)

**Google Sign-In Information:**
If you choose to sign in with Google, we receive:
- Your Google account email address
- Your Google account display name
- Your Google account profile picture URL
- Google account unique identifier

**Notification Preferences:**
- Firebase Cloud Messaging (FCM) token for push notifications
- Notification preference settings (which types of notifications you want to receive)
- Last daily reminder sent timestamp
- Preferred daily reminder time

### 2. Automatically Collected Information

When you use the App, we automatically collect certain information about your device and usage:

**Device Information:**
- Device type and model
- Operating system and version (Android)
- Unique device identifiers
- Mobile network information
- Time zone settings

**Usage Data:**
- Questions answered and answer accuracy
- Study sessions and duration
- Battle participation and results
- Streak data (daily study streaks, accuracy streaks)
- XP and level progression
- Achievement unlocks
- Leaderboard rankings
- Friend interactions (friend requests, accepted friendships)
- Matchmaking attempts and timestamps (for rate limiting)

**Firebase Analytics Data:**
- App opens and session duration
- Screen views and navigation patterns
- Feature usage statistics
- Crash reports and error logs
- Performance metrics

### 3. Information We Do Not Collect

We do NOT collect:
- Credit card or payment information (the app is currently free)
- Social Security numbers or government-issued ID numbers
- Precise geolocation data (GPS coordinates)
- Health information
- Biometric data
- Contact lists or phone numbers
- SMS or call logs

## How We Use Your Information

We use the information we collect for the following purposes:

### 1. Core App Functionality

**Account Management:**
- Create and manage user accounts
- Authenticate users securely
- Enable password reset functionality
- Facilitate Google Sign-In

**Educational Services:**
- Provide SAT and ACT practice questions
- Track study progress and performance
- Calculate skill-specific accuracy statistics
- Generate personalized question recommendations
- Maintain daily study streaks

**Battle Mode:**
- Match users for competitive battles based on level and test type
- Track battle results and statistics
- Calculate damage and health in real-time battles
- Maintain battle leaderboards

**Social Features:**
- Enable friend connections via friend codes
- Facilitate friend requests and acceptances
- Support friend-to-friend battles
- Display friends-only leaderboards

### 2. Communication

**Push Notifications:**
We send push notifications for:
- Friend requests received
- Friend requests accepted
- Battle invitations from friends
- Daily study reminders (at your chosen time)
- Streak warning notifications
- Achievement unlocks (when implemented)
- Leaderboard position changes (when implemented)

You can control which notifications you receive through in-app notification settings. Notifications can be disabled entirely through your device settings.

### 3. App Improvement and Analytics

- Monitor app performance and identify bugs
- Analyze usage patterns to improve features
- Generate anonymous aggregate statistics
- Conduct A/B testing for feature improvements
- Optimize question difficulty algorithms

### 4. Security and Fraud Prevention

- Detect and prevent cheating or score manipulation
- Implement rate limiting to prevent spam and abuse
- Monitor for suspicious activity
- Enforce time limits on battle answers
- Validate all game actions server-side

### 5. Legal Compliance

- Comply with applicable laws and regulations
- Respond to legal requests and prevent harm
- Enforce our Terms of Service
- Protect our rights and property

## How We Share Your Information

### Information Shared Publicly Within the App

The following information is visible to other users of the App:

**Public Profile Information:**
- Username
- Profile picture
- Level and XP
- Overall accuracy statistics
- Battle statistics (wins, losses, win rate)
- Achievements unlocked
- Leaderboard rankings

**NOT Publicly Visible:**
- Email address
- FCM notification token
- Detailed question-by-question answers
- Notification preferences
- Last login time
- Device information

### Third-Party Service Providers

We share information with trusted third-party service providers who assist us in operating the App:

**Firebase (Google LLC):**
- **Firebase Authentication:** Securely manages user authentication and passwords
- **Cloud Firestore:** Stores user profiles, questions, and persistent game data
- **Firebase Realtime Database:** Manages live battle state and matchmaking
- **Firebase Cloud Messaging:** Delivers push notifications
- **Firebase Cloud Functions:** Executes server-side game logic
- **Firebase Storage:** Hosts profile pictures and app assets
- **Firebase Analytics:** Tracks app usage and performance
- **Firebase Crashlytics:** Monitors app stability and crashes

Firebase processes data in accordance with Google's Privacy Policy: https://policies.google.com/privacy

**Google Sign-In (Google LLC):**
- Facilitates third-party authentication
- Processes data according to Google's Privacy Policy

**Google Mobile Ads (AdMob) - When Implemented:**
- Currently using test App ID (no real ads served)
- When implemented: will display personalized or non-personalized ads
- AdMob Privacy Policy: https://support.google.com/admob/answer/6128543

**Vertex AI (Google Cloud):**
- Generates SAT/ACT practice questions using AI (server-side only)
- Does NOT receive any user personal information
- Only receives question generation parameters (test type, skill, difficulty)

### Legal Requirements

We may disclose your information if required to do so by law or in response to:
- Valid legal processes (subpoenas, court orders)
- Governmental requests
- National security requirements
- Law enforcement investigations

We may also disclose information to:
- Enforce our Terms of Service
- Protect the rights, property, or safety of Prep Royale, our users, or the public
- Detect, prevent, or address fraud or security issues

### Business Transfers

In the event of a merger, acquisition, reorganization, bankruptcy, or sale of assets, your information may be transferred to the successor entity. We will notify you via email and/or prominent notice in the App before your information is transferred and becomes subject to a different privacy policy.

### With Your Consent

We may share your information for other purposes with your explicit consent.

## Data Retention

We retain your information for as long as your account is active or as needed to provide you services.

**Account Data:**
- Retained for the lifetime of your account
- Deleted when you delete your account (see Your Rights below)

**Battle Results:**
- Stored in Firestore permanently for historical records
- Deleted when you delete your account

**Active Battle Data:**
- Stored in Firebase Realtime Database during active battles
- Automatically removed after battle completion
- Abandoned battles (inactive >1 hour) marked as abandoned
- All battles older than 24 hours deleted automatically

**Matchmaking Logs:**
- Retained for 5 minutes (for rate limiting)
- Automatically deleted after expiration

**Notification Logs:**
- Retained for your reference
- Deleted when you delete your account

**Analytics Data:**
- Anonymous aggregate data may be retained indefinitely
- Personal identifiers removed after account deletion

## Data Security

We implement appropriate technical and organizational security measures to protect your information:

**Technical Safeguards:**
- All data transmitted using HTTPS/TLS encryption
- Passwords encrypted using Firebase Authentication (bcrypt)
- Server-side validation of all game actions
- Rate limiting to prevent abuse
- Regular security audits of Cloud Functions
- Firestore security rules prevent unauthorized access
- FCM tokens stored securely and auto-refreshed

**Organizational Safeguards:**
- Access to user data limited to essential operations
- Regular review of security practices
- Incident response procedures in place

**Limitations:**
No method of transmission over the Internet or electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your information, we cannot guarantee absolute security. You are responsible for maintaining the confidentiality of your account password.

## Your Privacy Rights

### Access and Portability

You have the right to:
- Access the personal information we hold about you
- Request a copy of your data in a portable format
- Review your profile, statistics, and battle history within the App

### Correction

You have the right to:
- Update your username through the profile settings
- Change your profile picture
- Update notification preferences
- Correct inaccurate information

### Deletion (Right to be Forgotten)

You have the right to delete your account and all associated data:

**How to Delete Your Account:**
Navigate to Settings > Account > Delete Account

**What Gets Deleted:**
- Your user profile (username, email, level, XP, stats)
- All friendships and friend requests
- All battle results and history
- All answered questions and progress
- Notification logs and preferences
- Leaderboard entries
- FCM notification token
- Firebase Authentication account

**Deletion Timeline:**
- Immediate upon confirmation
- Permanent and irreversible
- Some anonymous aggregate analytics may be retained

### Opt-Out of Communications

You have the right to:
- Disable specific notification types in Settings > Notifications
- Disable all push notifications through device settings
- Unsubscribe from promotional emails (when applicable)

### Data Portability

While we do not currently offer automated data export, you can:
- View all your data within the App
- Screenshot or manually record your statistics
- Request a data export (contact us through the App)

## Children's Privacy (COPPA Compliance)

The App is intended for users aged 13 and older. We do not knowingly collect personal information from children under 13 years of age.

**If you are under 13:**
Do not use the App or provide any personal information.

**If you are a parent or guardian:**
If you believe your child under 13 has provided personal information, please contact us immediately through the App. We will promptly delete such information.

**Age Verification:**
By creating an account, you affirm that you are at least 13 years old.

**Nebraska Law:**
Under Nebraska law, parental consent may be required for certain activities involving minors. Users under 18 should obtain parental permission before using the App.

## California Privacy Rights (CCPA)

If you are a California resident, you have additional rights under the California Consumer Privacy Act (CCPA):

- **Right to Know:** What personal information we collect, use, disclose, and sell
- **Right to Delete:** Request deletion of your personal information
- **Right to Opt-Out:** Opt-out of the sale of personal information (we do not sell data)
- **Right to Non-Discrimination:** Not be discriminated against for exercising your rights

We do not sell personal information to third parties.

## European Privacy Rights (GDPR)

If you are located in the European Economic Area (EEA), you have rights under the General Data Protection Regulation (GDPR):

- **Right of Access:** Access your personal data
- **Right to Rectification:** Correct inaccurate data
- **Right to Erasure:** Request deletion of your data
- **Right to Restriction:** Restrict processing of your data
- **Right to Data Portability:** Receive your data in a portable format
- **Right to Object:** Object to processing of your data
- **Right to Withdraw Consent:** Withdraw consent at any time

**Legal Basis for Processing:**
We process your data based on:
- **Consent:** You provide consent when creating an account
- **Contract Performance:** To provide App services
- **Legitimate Interests:** To improve the App and prevent fraud

## International Data Transfers

Your information may be transferred to and maintained on servers located outside of your state, province, country, or other governmental jurisdiction where data protection laws may differ.

**Firebase Infrastructure:**
- Data stored on Google Cloud servers (may be located globally)
- Google complies with Privacy Shield frameworks
- Adequate safeguards in place for international transfers

By using the App, you consent to the transfer of your information to the United States and other countries where Firebase operates.

## Cookies and Tracking Technologies

The App does not use traditional browser cookies. However, we use similar technologies:

**Firebase Analytics:**
- Collects anonymous usage data
- Uses identifiers for analytics purposes
- Can be limited through device settings

**Session Management:**
- Firebase Authentication uses tokens for session management
- Automatically managed by the SDK

**Advertising (When Implemented):**
- AdMob may use advertising identifiers
- You can reset your advertising ID in device settings
- You can opt-out of personalized ads

## Third-Party Links

The App may contain links to third-party websites or services (e.g., Google Sign-In). We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies.

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Changes will be effective when posted within the App. Material changes will be communicated through:
- In-app notification
- Email notification (if applicable)
- Updated "Last Updated" date

Continued use of the App after changes constitutes acceptance of the updated Privacy Policy.

## Your Consent

By using the App, you consent to:
- This Privacy Policy
- Our collection, use, and sharing of your information as described
- The transfer of your data to the United States and other countries

## Contact Us

For questions about this Privacy Policy or to exercise your rights, you can:
- Contact us through the App (Settings > Help & Support)
- Submit feedback through the in-app feedback form

We will respond to your request within 30 days.

---

## Summary of Key Points

**What We Collect:**
- Email, username, profile picture
- Study progress and battle statistics
- Device information and analytics
- Notification preferences

**How We Use It:**
- Provide educational services
- Enable battles and social features
- Send notifications (with your permission)
- Improve the App

**Who We Share With:**
- Firebase/Google (infrastructure)
- Other users (public profile only)
- Legal authorities (when required)

**Your Rights:**
- Access your data
- Correct your data
- Delete your account
- Control notifications
- Opt-out of analytics

**Data Security:**
- Encrypted transmission
- Secure storage
- Server-side validation
- Regular security audits

**Contact:**
- Through in-app support

---

**By creating an account and using Prep Royale, you acknowledge that you have read, understood, and agree to be bound by this Privacy Policy.**
