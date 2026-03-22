# MaJuTa — Security Model

## Overview

MaJuTa uses a two-layer security model: a **device-level gate** (biometrics/passcode) and a **cloud-level gate** (Firebase Auth + Firestore rules). The user only enters a PIN; all cryptographic operations are invisible.

---

## PIN Security

### Local storage (Keychain)

The PIN is never stored. Instead, a salted hash is stored:

```
salt  = cryptographically random 32 bytes (generated once at registration)
input = "<PIN>_<UUID>_majuta_salt"
hash  = PBKDF2-HMAC-SHA256(password: input, salt: salt, iterations: 100_000, keyLength: 32)
key   = "pin_<UUID>" in Keychain
```

- 100,000 PBKDF2 iterations ≈ 0.1 second per attempt on a modern device
- A 4-digit PIN space (10,000 guesses) takes ~17 minutes to exhaust
- A 6-digit PIN space takes ~28 hours
- **No lockout mechanism currently implemented** — see Known Limitations

### Firebase Auth password derivation

The Firebase password is derived deterministically so the user never manages a separate password:

```
input    = "fb_<PIN>_<UUID.uuidString>_majuta"
hash     = SHA256(input)
password = hex(hash)   # full 64-character hex string
```

Firebase applies bcrypt server-side, making server-side brute-force expensive. However, this derivation uses a single SHA256 round — see Known Limitations.

### Legacy migration

Accounts created before the PBKDF2 upgrade used `SHA256("<PIN>_<UUID>_majuta_salt")` for local storage. `UserService` detects the legacy format on first login and silently migrates to PBKDF2.

---

## Keychain Storage

All sensitive per-user data is stored with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`:

| Key | Contents | Protection |
|---|---|---|
| `registered_users_v1` | `[UserProfile]` JSON | Device-locked, not iCloud backed |
| `registered_households_v1` | `[RegisteredHousehold]` JSON | Device-locked, not iCloud backed |
| `pin_<UUID>` | PBKDF2 hash + salt | Device-locked, not iCloud backed |
| `lastLoggedInUserId` | UUID string | Device-locked |
| `biometric_<UUID>` | `"true"` flag | Device-locked |
| `invite_household_<householdId>` | 6-digit code string | Device-locked |

`kSecAttrAccessibleWhenUnlockedThisDeviceOnly` means:
- Items are **inaccessible when the device is locked** (data at rest encrypted)
- Items are **not transferred to new devices** (no iCloud Keychain sync)
- Items are **not included in device backups**

---

## Local File Protection

Guest mode data (`guest_data.json`) and profile images are written with `.completeFileProtection`:

```swift
try? encoded.write(to: Self.guestDataURL, options: [.atomic, .completeFileProtection])
```

`.completeFileProtection` uses a key derived from the user's device passcode. Files are inaccessible when the device is locked.

---

## Firebase Auth

- Authentication method: email + derived password (user never sees the password)
- Email verification required before full app access (can be skipped in current build)
- Password reset would require re-deriving the password from the PIN — no "forgot password" flow is implemented
- Firebase Auth applies bcrypt server-side to all stored passwords

---

## Firestore Security Rules

Rules are in `firestore.rules` and deployed via `firebase deploy --only firestore:rules`.

### Core principles

1. **Household isolation** — all financial data is scoped under `/households/{householdId}/`. No user can read another household's data.
2. **authLookup bridge** — the `authLookup` collection maps Firebase UID → householdId. Rules use this to verify membership without embedding it in the auth token.
3. **authLookup is immutable** — `update` and `delete` are blocked. A user cannot switch their householdId.
4. **Role enforcement** — `owner` and `admin` can write shared resources; `member` can add transactions but cannot delete others' data.
5. **Audit log integrity** — `authLogs` entries must have `uid == request.auth.uid`; updates and deletes are blocked.

### Per-collection summary

| Collection | Read | Create | Update | Delete |
|---|---|---|---|---|
| `authLookup` | Own UID only | Own UID only | **Blocked** | **Blocked** |
| `users` | Same household | Self only | Self or same-household admin | **Blocked** |
| `households` | Own household | Own household (owner) | Own household (owner) | Own household (owner) |
| `transactions` | Own household | Own household, `createdByUserId` pinned | Own household, ownership fields immutable | Own household, creator or owner |
| `bills` | Own household | Own household (canAddTx) | Own household, owner or creator | Own household (canWrite) |
| `activityLog` | Own household | Own household, `userId` must match caller | **Blocked** | **Blocked** |
| `authLogs` | **Blocked** (console only) | `uid` must match `request.auth.uid` | **Blocked** | **Blocked** |
| `inviteCodes` | Any authenticated user | Own household (canWrite) | **Blocked** | Own household (owner) |

### Deploy rules after any change

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

---

## Privacy Screen

When the app moves to the background (`scenePhase != .active`), a full black overlay covers all content:

```swift
.overlay {
    if scenePhase != .active {
        ZStack { Color.black.opacity(0.85) ... }
        .ignoresSafeArea()
    }
}
```

This prevents financial data from appearing in the App Switcher screenshot.

---

## Deep Link Security

The `majuta://email-verified` URL scheme is handled with guards:

```swift
.onOpenURL { url in
    guard url.scheme == "majuta",
          url.host == "email-verified" else { return }
    Task {
        await FirebaseAuthService.shared.handleEmailVerifiedDeepLink()
        // Requires a live Firebase session to be present
        guard FirebaseAuthService.shared.firebaseUID != nil,
              FirebaseAuthService.shared.isEmailVerified else { return }
        authService.isAuthenticated = true
    }
}
```

- URL parameters are not parsed — no injection vector
- `firebaseUID != nil` guard prevents a spoofed deep link from granting auth if no Firebase session exists
- Authentication is confirmed with Firebase server before granting access

---

## Known Security Limitations

### 1. No PIN brute-force lockout
There is no failed-attempt counter or exponential back-off. A script on a jailbroken device could attempt all PINs offline.

**Mitigation:** PBKDF2 with 100k iterations makes each attempt ~0.1s, limiting a 4-digit attack to ~17 minutes on-device.

**Recommended fix:** Add a Keychain-stored attempt counter with exponential back-off and biometric re-challenge after 5 failures.

### 2. Firebase password uses single-round SHA256
The Firebase Auth password (`SHA256("fb_<PIN>_<UUID>_majuta")`) uses one SHA256 iteration. Firebase bcrypt protects against server-side brute force, but if Firebase's hashed passwords were ever leaked, the raw SHA256 input could be recovered quickly given the small PIN space.

**Recommended fix:** Replace with PBKDF2 derivation (the infrastructure already exists in `UserService.hashPIN`). Requires a migration flow to re-derive and update Firebase passwords on first login.

### 3. Invite codes readable by any authenticated user
The `inviteCodes` collection allows any authenticated user to read any code document if they know the code string. The 12-character alphanumeric code provides ~58 bits of entropy (brute force impractical), but the `householdId` stored in the code is visible.

### 4. No Firebase App Check
The Firebase Web API key embedded in `GoogleService-Info.plist` is extractable from the app binary. Without App Check (DeviceCheck/App Attest), the API key could be used to make Firebase Auth requests from outside the app.

**Recommended fix:** Enable Firebase App Check in the Firebase console — no code changes required.

### 5. Account balance is not atomic
Concurrent offline edits to `account.balance` use last-write-wins at Firestore. Two members adding transactions simultaneously while offline could result in an inconsistent balance.

**Recommended fix:** Use `FieldValue.increment(delta)` for balance updates instead of reading-modifying-writing the full document.

---

## Reporting Security Issues

Please report security vulnerabilities privately by opening a GitHub issue marked **[SECURITY]** or contacting the maintainer directly. Do not disclose vulnerabilities publicly until they have been addressed.
