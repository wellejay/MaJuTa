# MaJuTa — تطبيق إدارة الميزانية العائلية

Personal and family finance management app for Saudi Arabic users. Built with SwiftUI + Firebase.

---

## Table of Contents

1. [Overview](#overview)
2. [Tech Stack](#tech-stack)
3. [Project Structure](#project-structure)
4. [Authentication System](#authentication-system)
5. [Registration & Email Verification Flow](#registration--email-verification-flow)
6. [PIN & Biometric Auth Flow](#pin--biometric-auth-flow)
7. [Multi-User / Household System](#multi-user--household-system)
8. [Data Architecture](#data-architecture)
9. [Firestore Security Rules](#firestore-security-rules)
10. [Financial Engines — All Math](#financial-engines--all-math)
    - [CashFlowEngine](#cashflowengine)
    - [FinancialHealthEngine](#financialhealthengine)
    - [InvestmentEngine](#investmentengine)
11. [DataStore — Computed Metrics](#datastore--computed-metrics)
12. [Keychain Storage](#keychain-storage)
13. [Firebase Setup & Deployment](#firebase-setup--deployment)
14. [iOS App Setup](#ios-app-setup)
15. [Deep Link Flow](#deep-link-flow)
16. [Known Limitations](#known-limitations)
17. [Simulator Log Noise](#simulator-log-noise)

---

## Overview

MaJuTa (ماجوتا) is an Arabic-first iOS app for:
- Tracking income and expenses (transactions)
- Managing bills and recurring obligations
- BNPL / installment tracking
- Savings goals
- Investment portfolio
- Financial health scoring
- Multi-user household sharing

**Target:** iOS 16+ | Arabic RTL UI | SAR (Saudi Riyal) currency

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI | SwiftUI iOS 17+ (RTL, Arabic-first) |
| Auth | Firebase Authentication (email/password) |
| Database | Cloud Firestore (real-time listeners) |
| Hosting | Firebase Hosting |
| Local cache | Keychain `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |
| App state | `@AppStorage` (UserDefaults) for non-sensitive prefs |
| Engines | CashFlow, FinancialHealth, Investment, Zakat, Ledger |
| Font | `SaudiRiyal.ttf` — custom Saudi Riyal glyph (U+E900) |
| Crypto | `CryptoKit` — PBKDF2-HMAC-SHA256 (PIN), SHA256 (Firebase password) |
| Biometrics | `LocalAuthentication` — Face ID → Touch ID → Device Passcode |
| Build | XcodeGen (`project.yml`) + Swift Package Manager |
| CI/CD | GitHub Actions (`.github/workflows/`) |

---

## Project Structure

```
MaJuTa/
├── App/
│   ├── MaJuTaApp.swift          # @main entry, routing logic, deep link handler
│   └── AppState.swift           # Global UI state: onboarding, color scheme, profile image
│
├── Core/
│   ├── Models/
│   │   ├── User.swift           # User + UserProfile + UserRole structs
│   │   ├── Household.swift      # RegisteredHousehold struct
│   │   ├── Transaction.swift    # Transaction + PaymentMethod + TransactionCategory
│   │   ├── Account.swift        # Account + AccountType (checking, savings, cash, etc.)
│   │   ├── Bill.swift           # Bill + BillStatus + frequency
│   │   ├── BNPLInstallment.swift # InstallmentPlan + Installment
│   │   ├── SavingsGoal.swift    # SavingsGoal struct
│   │   ├── Investment.swift     # InvestmentAsset + AssetType + Market
│   │   ├── Category.swift       # TransactionCategory + ParentCategory
│   │   └── UserModels.swift     # UserProfile, RegisteredHousehold, ActivityEntry
│   │
│   ├── Services/
│   │   ├── DataStore.swift          # In-memory store + Firestore listeners + computed metrics
│   │   ├── UserService.swift        # Registration, PIN, multi-user management, Keychain persistence
│   │   ├── AuthenticationService.swift  # App-level auth state (biometric/passcode gating)
│   │   ├── FirebaseAuthService.swift    # Firebase Auth: create account, sign in, email verify
│   │   └── FirestoreService.swift       # Generic Firestore CRUD, real-time listeners, authLookup
│   │
│   ├── Engines/
│   │   ├── CashFlowEngine.swift         # All income/expense/savings math
│   │   ├── FinancialHealthEngine.swift  # Health score algorithm (0–100)
│   │   └── InvestmentEngine.swift       # Portfolio value, P&L, allocation
│   │
│   ├── Security/
│   │   └── KeychainService.swift        # Thin Security.framework wrapper (CRUD)
│   │
│   └── Persistence/
│       └── PersistenceController.swift  # CoreData stack (configured, not yet used for CRUD)
│
├── Features/
│   ├── Auth/
│   │   ├── RegistrationView.swift       # New user / join household form
│   │   ├── EmailVerificationView.swift  # Post-registration verification screen
│   │   ├── UserPickerView.swift         # Select which user to log in as
│   │   └── PINPadView.swift             # 6-digit PIN entry pad
│   │
│   ├── Onboarding/    OnboardingView.swift
│   ├── Dashboard/     DashboardView.swift, MainTabView.swift, LockScreenView.swift
│   ├── Transactions/  TransactionsListView.swift, AddTransactionView.swift
│   ├── Bills/         BillsView.swift
│   ├── Installments/  InstallmentsView.swift
│   ├── Goals/         GoalsView.swift, GoalDetailView.swift, EmergencyFundView.swift
│   ├── Investments/   InvestmentsView.swift
│   ├── Analytics/     AnalyticsView.swift
│   ├── FinancialHealth/ FinancialHealthView.swift
│   ├── Accounts/      AccountsView.swift
│   ├── Family/        FamilyView.swift
│   ├── ReceiptScanner/ ReceiptScannerView.swift
│   └── Settings/      SettingsView.swift, ProfileView.swift
│
├── DesignSystem/
│   ├── Tokens/          Colors, Typography, Spacing, Radius constants
│   └── Components/      Cards, SARText, TransactionRowView, BillRowView, etc.
│
└── Resources/
    ├── Assets.xcassets  (AppIcon — empty, needs images)
    ├── Info.plist       (URL scheme, camera, Face ID permissions)
    └── SaudiRiyal.ttf
```

---

## Authentication System

The app has **two separate auth layers** that work in sequence:

```
Layer 1 — App Lock (LocalAuthentication)
    Controlled by: AuthenticationService
    Purpose: Gates access to the app on device
    Methods: Face ID → Touch ID → Device Passcode (auto-fallback chain)

Layer 2 — Firebase Auth (Remote)
    Controlled by: FirebaseAuthService
    Purpose: Syncs data from Firestore, verifies email ownership
    Method: Email + derived password
```

### Why two layers?
- Layer 1 (LAContext) protects the app on-device without a password UI — the system passcode prompt appears natively.
- Layer 2 (Firebase) enables cloud sync and email verification. The user never types a Firebase password — it's computed from their PIN.

### Firebase Password Derivation

The Firebase Auth password is **deterministically derived** from the user's PIN and UUID:

```
input  = "fb_<PIN>_<UUID>_majuta"
hash   = SHA256(input)
password = hex(hash).prefix(32)   // first 32 hex characters
```

Example:
```
PIN: "123456"
UUID: "550e8400-e29b-41d4-a716-446655440000"
input: "fb_123456_550E8400-E29B-41D4-A716-446655440000_majuta"
password: "a3f2..." (32-char hex)
```

This means:
- The user only ever enters their PIN
- Firebase Auth password is never stored or shown
- If the user changes their PIN, the Firebase password changes — `FirebaseAuthService.signIn()` recomputes it on each login

### PIN Hashing (local storage)

The PIN is stored in Keychain as a salted SHA256 hash (separate from the Firebase derivation):

```
input = "<PIN>_<UUID>_majuta_salt"
hash  = SHA256(input) → full 64-char hex
key   = "pin_<UUID>"
```

The PIN itself is never stored. Verification is: `hash(entered PIN) == stored hash`.

---

## Registration & Email Verification Flow

### Full Registration Sequence

```
RegistrationView (user fills form)
    │
    ├─ Validate: username available? email available? phone available?
    │   └─ UserService.isUsernameAvailable() — checks local Keychain cache
    │   └─ UserService.isEmailAvailable()
    │   └─ UserService.isPhoneAvailable() — compares last 9 digits
    │
    └─ UserService.register(name, username, email, phone, pin)
            │
            ├─ 1. Create UUID for user and household
            ├─ 2. FirebaseAuthService.createAccount(email, pin, userId)
            │       ├─ Derives password: SHA256("fb_<pin>_<uuid>_majuta").prefix(32)
            │       ├─ Auth.auth().createUser(withEmail: email, password: derived)
            │       ├─ Stores firebaseUID locally
            │       └─ Sends verification email with ActionCodeSettings:
            │               continueURL = https://majuta-880aa.web.app/verified
            │               handleCodeInApp = false
            │               iOS bundle ID = com.majuta.app
            │
            ├─ 3. AWAIT FirestoreService.saveAuthLookup(uid, userId, householdId)
            │       └─ /authLookup/{firebaseUID} = {userId, householdId}
            │          (awaited so security rules can resolve household membership
            │           for all subsequent Firestore writes)
            │
            ├─ 4. PIN hash → Keychain "pin_<UUID>"
            ├─ 5. User + Household → append to local registeredUsers array
            ├─ 6. saveUsersToKeychain() — persist full user list
            ├─ 7. FirestoreService.saveUser(user) → /users/{userId}
            ├─ 8. FirestoreService.saveHousehold(household) → /households/{householdId}
            └─ 9. generateInviteCode() → 6-digit code → Keychain + Firestore /inviteCodes/{code}

RegistrationView.finishRegistration()
    ├─ isEmailVerified? → authService.isAuthenticated = true → MainTabView
    └─ not verified    → authService.showEmailVerification = true → EmailVerificationView
```

### Email Verification Screen (`EmailVerificationView`)

- Pulsing envelope animation
- Shows the registered email address
- Auto-checks on `scenePhase == .active` (app foregrounded)
- **"لقد قمت بالتحقق ✓"** — manually triggers `FirebaseAuthService.reloadVerificationStatus()` then proceeds
- **"إعادة إرسال البريد"** — calls `FirebaseAuthService.resendVerificationEmail()`
- **"تخطى للآن"** — sets `showEmailVerification = false` and `isAuthenticated = true` (skips verification)

### Email Link Flow (deep link)

```
User receives email → taps verification link
    → Firebase action page processes the link
    → Firebase redirects to https://majuta-880aa.web.app/verified
    → verified.html runs on load:
            setTimeout(() => window.location.href = "majuta://email-verified", 500)
    → iOS opens MaJuTa app via custom URL scheme
    → MaJuTaApp.onOpenURL handles majuta://email-verified:
            await FirebaseAuthService.shared.handleEmailVerifiedDeepLink()
            // calls Auth.auth().currentUser?.reload()
            // updates isEmailVerified from Firebase
            if isEmailVerified {
                authService.showEmailVerification = false
                authService.isAuthenticated = true
            }
```

---

## PIN & Biometric Auth Flow

### App Launch Routing (MaJuTaApp)

```
if userService.registeredUsers.isEmpty || authService.showRegistration
    → RegistrationView

else if authService.showEmailVerification
    → EmailVerificationView

else if !authService.isAuthenticated
    → UserPickerView  (select user → biometric/passcode prompt)

else if userService.currentUser != nil
    if appState.hasCompletedOnboarding
        → MainTabView
    else
        → OnboardingView
```

### AuthenticationService.authenticate()

```swift
// 1. Try biometrics (Face ID / Touch ID)
LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)
    success → isAuthenticated = true, loadUserData()
    failure → fall through to step 2

// 2. Fall back to full device auth (passcode)
LAContext.evaluatePolicy(.deviceOwnerAuthentication)
    success → isAuthenticated = true, loadUserData()
    failure → authError set, isAuthenticated stays false
```

The `biometricType` property detects Face ID vs Touch ID vs none at runtime. No custom PIN UI is shown — the system passcode prompt appears natively.

### After successful authentication

```
UserService.setCurrentUser(user)
    → persists "lastLoggedInUserId" to Keychain

DataStore.shared.loadForCurrentUser()
    → removes all old Firestore listeners
    → clears local data
    → attaches 8 real-time Firestore listeners for the household:
        accounts, transactions, savingsGoals, bills,
        investments, installmentPlans, installments, activityLog

UserService.signInToFirebase(user, pin)
    → recomputes Firebase password from PIN
    → Auth.auth().signIn(email, password)
    → syncFromFirestore(user)
        → loads household members from /users where householdId matches
        → loads household document
        → merges into local registeredUsers array
        → saves to Keychain
```

---

## Multi-User / Household System

### Concepts

- **Household** — a shared financial unit. All members see the same accounts, transactions, bills, goals, investments.
- **UserProfile** — a person registered on the device. Has a role (`owner` or `member`).
- **Multiple users per device** — `UserPickerView` shows all registered users. Each selects themselves and authenticates with their own biometric/passcode.

### Roles and Permissions

| Action | Owner | Member |
|---|---|---|
| Add transactions | ✓ | ✓ |
| Edit shared accounts | ✓ | ✗ |
| Delete any transaction | ✓ | own only |
| Remove household members | ✓ | ✗ |

Checked via `DataStore.canEdit()`, `canAdd()`, `canDelete()`.

### Invite Code System

On registration, a 6-digit invite code is generated:
```
code = String(format: "%06d", Int.random(in: 100000...999999))
```
Stored in:
- Keychain: key `"invite_household_<householdId>"`
- Firestore: `/inviteCodes/{code}` → `{householdId}`

A second user joins by:
1. Entering the invite code in RegistrationView
2. App looks up code in Firestore → gets householdId
3. `UserService.addMember()` creates the user with `role = .member` and the same `householdId`
4. `saveAuthLookup()` is awaited so their Firebase UID maps to the household

### Firestore Data Isolation

All household data lives under `/households/{householdId}/` subcollections. Firestore security rules use `authLookup` to verify that the requesting Firebase UID belongs to the correct household before allowing read/update/delete.

---

## Data Architecture

### Real-time Listeners (DataStore)

On login, `DataStore.loadForCurrentUser()` attaches Firestore snapshot listeners for all 8 collections. Updates arrive in real-time and are written to `@Published` arrays, triggering SwiftUI view updates.

```
/households/{householdId}/
    accounts/           → DataStore.accounts
    transactions/       → DataStore.transactions (sorted: newest first)
    savingsGoals/       → DataStore.savingsGoals
    bills/              → DataStore.bills (sorted: due date)
    investments/        → DataStore.investments
    installmentPlans/   → DataStore.installmentPlans
    installments/       → DataStore.installments (sorted: due date)
    activityLog/        → DataStore.activityLog (newest first, max 100 entries)
```

### Visibility Rules

Not all data is shown to every user in a multi-user household:

```swift
// Accounts: owned by user OR marked as shared
visibleAccounts = accounts.filter { $0.isShared || $0.ownerUserId == currentUser.id }

// Transactions: only those belonging to visible accounts
visibleTransactions = transactions.filter { visibleAccountIds.contains($0.accountId) }

// Goals: owned by user OR marked as shared
visibleGoals = savingsGoals.filter { $0.isShared || $0.ownerUserId == currentUser.id }

// Bills: owned by user OR tied to a visible account
visibleBills = bills.filter { $0.ownerUserId == currentUser.id
                           || visibleAccountIds.contains($0.accountId) }
```

### Keychain Storage Map

| Key | Value | Purpose |
|---|---|---|
| `registered_users_v1` | `[UserProfile]` JSON | All users on this device |
| `registered_households_v1` | `[RegisteredHousehold]` JSON | All households on this device |
| `pin_<UUID>` | SHA256 hex string | Hashed PIN per user |
| `lastLoggedInUserId` | UUID string | Remember last logged-in user |
| `biometric_<UUID>` | "true" | Biometric opt-in flag per user |
| `invite_household_<householdId>` | 6-digit string | Invite code for household |

Keychain items use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — not backed up to iCloud, not available when device is locked.

---

## Firestore Security Rules

File: `/tmp/majuta-firebase/firestore.rules`

```
/authLookup/{firebaseUID}
    read/write: only the authenticated user matching the firebaseUID
    Purpose: maps Firebase UID → {userId, householdId} for rule evaluation

/users/{userId}
    read:   any authenticated user
    create: any authenticated user
    update/delete: only if resource.data.firebaseUID == request.auth.uid

/households/{householdId}
    create: any authenticated user (registration — authLookup may not exist yet)
    read/update/delete: isInHousehold(householdId)

/households/{householdId}/{subcollection}/{docId}
    create: any authenticated user (scoped by path)
    read/update/delete: isInHousehold(householdId)

/inviteCodes/{code}
    read/write: any authenticated user

function isInHousehold(householdId):
    ref = /authLookup/{request.auth.uid}
    return exists(ref) && get(ref).data.householdId == householdId
```

**Why `create` is open for households:** During registration, `saveAuthLookup()` is awaited before `saveHousehold()`. However, this is an async network call — a brief race condition window exists. Allowing any authenticated user to create a household eliminates permission errors while the authLookup propagates.

---

## Financial Engines — All Math

### CashFlowEngine

All functions are static. No state.

#### Income / Expenses
```
totalIncome(transactions)     = sum of all amounts > 0
totalExpenses(transactions)   = sum of abs(amount) for all amounts < 0
netCashFlow(income, expenses) = totalIncome - totalExpenses
```

#### Safe To Spend
```
safeToSpend = liquidCash - upcomingBills - plannedSavings - emergencyContribution
```
Where:
- `liquidCash` = sum of balances of all liquid accounts
- `upcomingBills` = sum of bills due within next 30 days (status = upcoming, not overdue)
- `plannedSavings` = sum of monthly contributions needed for all active savings goals
- `emergencyContribution` = 10% of monthly income (constant target)

#### Savings Rate
```
savingsRate = (savingsContributions / disposableIncome) × 100
```
Returns 0 if disposableIncome ≤ 0.

#### Emergency Fund Coverage
```
emergencyMonths = emergencyBalance / monthlyEssentials
```
Where `emergencyBalance` = balance of all savings-type accounts.
`monthlyEssentials` = 3-month rolling average of transactions in "essential" categories.

If no essential expense data exists, fallback = `max(monthlyIncome × 0.5, 1)`.

#### Fixed Obligation Ratio (Debt Ratio)
```
fixedObligationRatio = (upcomingBillsTotal + monthlyInstallmentPayments) / monthlyIncome
```
Returns 0 if income = 0.

Risk thresholds:
```
ratio < 0.40  → healthy (ممتاز)
ratio < 0.60  → warning (تحذير)
ratio ≥ 0.60  → high risk (خطر)
```

#### Spending Stability
```
// Last 3 months of expense totals
months = [month0_expenses, month1_expenses, month2_expenses]  (only non-zero months)

// Need ≥ 2 months to compute
avg      = mean(months)
variance = mean((x - avg)² for x in months)
cv       = sqrt(variance) / avg          // coefficient of variation
stability = max(0, min(100, (1 - min(1, cv)) × 100))
```
A perfectly consistent spender scores 100. High variance → lower score.

#### Budget Variance
```
variance           = actual - planned
variancePercentage = (actual - planned) / planned × 100
```

#### Spending Anomaly Detection
```
isAnomaly = todaySpend > 2 × thirtyDayAverage
thirtyDayAverage = totalExpenses(last30days) / 30
```

#### Sinking Fund (Goal Contribution)
```
monthlyContribution = targetAmount / monthsUntilDue
```
If deadline = nil, assumes 12 months.

---

### FinancialHealthEngine

Produces a `FinancialHealthScore` struct with total (0–100) and 4 component scores.

#### Score Formula
```
total = (savingsScore × 0.30)
      + (emergencyScore × 0.25)
      + (debtScore × 0.25)
      + (stabilityScore × 0.20)
```

If `hasData = false` (no transactions at all), returns all zeros.

#### Component Scorers

**Savings Rate Score** (input: rate as %)
```
rate ≥ 20%         → 100
15% ≤ rate < 20%   → 75 + (rate - 15) × 5
10% ≤ rate < 15%   → 50 + (rate - 10) × 5
5% ≤ rate < 10%    → 25 + (rate - 5) × 5
rate < 5%          → max(0, rate × 5)
```

**Emergency Coverage Score** (input: months of coverage)
```
months ≥ 6         → 100
3 ≤ months < 6     → 50 + (months - 3) × (50/3)
1 ≤ months < 3     → (months - 1) × 25
months < 1         → 0
```

**Debt Ratio Score** (input: ratio 0.0–1.0+)
```
ratio < 0.20       → 100
0.20 ≤ ratio < 0.40 → 75 - ((ratio - 0.20) / 0.20) × 25
0.40 ≤ ratio < 0.60 → 50 - ((ratio - 0.40) / 0.20) × 25
ratio ≥ 0.60        → max(0, 25 - ((ratio - 0.60) / 0.40) × 25)
```

**Spending Stability Score** (input: 0–100)
```
= min(stability, 100)    // passthrough, already 0-100
```

#### Score Grades
```
80–100 → ممتاز   (Excellent) — green  #22C55E
60–79  → جيد     (Good)      — gold   #F2AE2E
40–59  → مقبول   (Fair)      — orange #F27F1B
0–39   → ضعيف   (Poor)      — red    #EF4444
```

#### Why a New Account Scores 25
```
No savings goals set    → savingsRate = 0  → savingsScore = 0  → 0 × 0.30 = 0
No savings account      → emergencyMonths = 0 → emergencyScore = 0 → 0 × 0.25 = 0
No bills/installments   → fixedObligationRatio = 0 → debtScore = 100 → 100 × 0.25 = 25
Only 1 month of data    → spendingStability = 0 (needs ≥ 2 months) → 0 × 0.20 = 0

Total = 25
```

---

### InvestmentEngine

#### Portfolio Value
```
portfolioValue = sum(asset.currentMarketValue for all assets)
```
Where `currentMarketValue = shares × lastPrice`.

#### Cost Basis & P&L
```
totalCostBasis  = sum(asset.costBasis for all assets)
totalProfitLoss = portfolioValue - totalCostBasis
overallReturn % = (totalProfitLoss / totalCostBasis) × 100
```

#### Asset Allocation
```
allocation[assetType] = (sum of currentMarketValue for that type) / portfolioValue × 100
```
Returns a `[AssetType: Double]` dictionary of percentages.

#### Price Staleness
```
isPriceStale = hoursSinceLastUpdate > 24    // for both Tadawul and international markets
```

---

## DataStore — Computed Metrics

These properties are called by `FinancialHealthView` and `DashboardView`:

```swift
monthlyIncome(date)         // sum of positive transactions in the given month
monthlyExpenses(date)       // sum of abs(negative transactions) in the given month
netCashFlow(date)           // income - expenses

totalLiquidCash             // sum of balances of isLiquid accounts
upcomingBillsTotal          // bills due within 30 days (upcoming, not overdue)
monthlyInstallmentPayments  // installments due within 30 days (upcoming)

safeToSpend                 // CashFlowEngine.safeToSpend(liquidCash, bills, savings, emergency)

plannedSavingsThisMonth     // sum of (remaining / monthsUntilDeadline) for each active goal
emergencyMonthlyContribution // monthlyIncome × 0.10

emergencyFundBalance        // sum of balances of savings-type accounts
avgMonthlyEssentialExpenses // 3-month rolling avg of essential-category expenses
emergencyMonths             // emergencyFundBalance / avgMonthlyEssentialExpenses

fixedObligationRatio        // (bills + installments) / monthlyIncome
spendingStability           // coefficient of variation over last 3 months → 0–100

portfolioValue              // InvestmentEngine.portfolioValue(investments)
netWorth                    // totalAssets + portfolioValue - 0 (liabilities not yet tracked)
```

---

## Keychain Storage

`KeychainService` wraps `Security.framework` directly. Items use:
- `kSecClassGenericPassword`
- `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (not iCloud backed, requires device unlock)

Supported types: `String`, `Data`, `Double`.

Write pattern:
```
SecItemDelete(existing)   // always delete first to avoid duplicate errors
SecItemAdd(new item)
```

Read pattern:
```
SecItemCopyMatching(query, &result)
```

---

## Firebase Setup & Deployment

### Firebase Project
- **Project ID:** `majuta-880aa`
- **Bundle ID:** `com.majuta.app`
- **Hosting URL:** `https://majuta-880aa.web.app`

### Deploy Firestore rules
```bash
cd /tmp/majuta-firebase
firebase deploy --only firestore:rules
```

### Deploy Hosting (email redirect page)
```bash
cd /tmp/majuta-firebase
firebase deploy --only hosting
```

Deployed files:
- `/verified` → `public/verified.html` — auto-redirects to `majuta://email-verified`
- `/.well-known/apple-app-site-association` — Universal Links config
  - **Action needed:** Replace `TEAMID` with your Apple Developer Team ID

### Firestore Collections

```
/authLookup/{firebaseUID}
    userId: String (UUID)
    householdId: String (UUID)

/users/{userId}
    id, name, username, email, phoneNumber, householdId,
    role, avatarColorHex, firebaseUID, createdAt

/households/{householdId}
    id, name, ownerUserId, createdAt

/households/{householdId}/accounts/{id}
/households/{householdId}/transactions/{id}
/households/{householdId}/savingsGoals/{id}
/households/{householdId}/bills/{id}
/households/{householdId}/investments/{id}
/households/{householdId}/installmentPlans/{id}
/households/{householdId}/installments/{id}
/households/{householdId}/activityLog/{id}

/inviteCodes/{code}
    householdId: String (UUID)
```

---

## iOS App Setup

### Requirements
- Xcode 15.0+
- iOS 17.0 deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- Firebase CLI — `npm install -g firebase-tools`
- `GoogleService-Info.plist` (download from Firebase Console → Project Settings)
- Apple Developer account (for device deployment)

### Installation
```bash
# 1. Clone the repo
git clone <repo-url> && cd MaJuTa

# 2. Add GoogleService-Info.plist (never committed — gitignored)
cp /path/to/GoogleService-Info.plist MaJuTa/Resources/

# 3. Generate the Xcode project from project.yml
xcodegen generate --spec project.yml

# 4. Open in Xcode — SPM packages resolve automatically
open MaJuTa.xcodeproj
```

Firebase dependencies are declared in `project.yml` and resolved via Swift Package Manager — no Podfile or Podfile.lock.

### Localization

The app uses a custom `L()` function instead of `NSLocalizedString`:

```swift
// Core/Localization/L.swift
func L(_ key: String) -> String {
    let lang = UserDefaults.standard.string(forKey: "appLanguage") ?? "ar"
    guard lang != "ar" else { return key }  // Arabic keys ARE the text
    guard let bundle = Bundle(path: Bundle.main.path(forResource: lang, ofType: "lproj")!)
    else { return key }
    return bundle.localizedString(forKey: key, value: key, table: nil)
}
```

- **Arabic** is the development language — keys are the Arabic strings themselves
- **English** translations live in `Resources/en.lproj/Localizable.strings`
- Language switching is in-app (no app restart needed) via `AppState.appLanguage`
- To add a new string: use it with `L("عربي")` in code, add the English translation to `en.lproj/Localizable.strings`

### Info.plist Permissions
```xml
NSCameraUsageDescription    → نحتاج الكاميرا لمسح الفواتير والإيصالات
NSFaceIDUsageDescription    → استخدام Face ID لحماية بياناتك المالية
CFBundleURLTypes            → majuta:// custom URL scheme
UIRequiresFullScreen        → true
UISupportedInterfaceOrientations → Portrait only
UIUserInterfaceStyle        → Automatic (supports dark mode)
UIAppFonts                  → SaudiRiyal.ttf
```

---

## Deep Link Flow

```
URL: majuta://email-verified

MaJuTaApp.onOpenURL handler:
    guard url.scheme == "majuta" && url.host == "email-verified"

    Task:
        await FirebaseAuthService.shared.handleEmailVerifiedDeepLink()
        // → Auth.auth().currentUser?.reload()
        // → isEmailVerified = currentUser.isEmailVerified

        if isEmailVerified:
            authService.showEmailVerification = false
            authService.isAuthenticated = true
            // → app routes to MainTabView / OnboardingView
```

---

## Known Limitations

| Issue | Impact | Status |
|---|---|---|
| **Data not persisted across restarts** | All DataStore mutations are in-memory. Firestore listeners repopulate on next login, but any add/edit made during a session that didn't sync will be lost if app crashes. | CoreData schema exists but not wired to CRUD |
| **AppIcon missing** | App shows grey placeholder icon on simulator and device | Assets.xcassets/AppIcon.appiconset has no images |
| **AASA Team ID placeholder** | Universal Links do not work — custom URL scheme (`majuta://`) works as fallback | Replace `TEAMID` in `public/.well-known/apple-app-site-association` |
| **Spending stability needs 2+ months** | Score component always 0 for new users until second calendar month has expense data | By design — not a bug |
| **Investment prices manual** | No live price feed — user must update prices manually | MVP scope |

---

## CI/CD

GitHub Actions workflows live in `.github/workflows/`:

| Workflow | Trigger | Purpose |
|---|---|---|
| `ci.yml` | Push/PR to `main` | Build + run all unit tests |
| `lint.yml` | Push/PR to `main` | SwiftLint — fails on errors |
| `release.yml` | Tag `v*` | Archive → export IPA → upload to TestFlight |

SwiftLint config: `.swiftlint.yml` — 150-char line limit, SwiftUI nesting disabled, `force_cast`/`force_try`/`empty_catch` enabled.

To trigger a TestFlight release:
```bash
git tag v1.0.0 && git push origin v1.0.0
```

Required GitHub Secrets for release: `APPLE_ID`, `APP_SPECIFIC_PASSWORD`, `TEAM_ID`, `DISTRIBUTION_CERTIFICATE_BASE64`, `DISTRIBUTION_CERTIFICATE_PASSWORD`, `PROVISIONING_PROFILE_BASE64`, `KEYCHAIN_PASSWORD`.

---

## Contributing

1. Create a feature branch: `git checkout -b feat/my-feature`
2. Run SwiftLint before committing: `swiftlint lint --config .swiftlint.yml`
3. Regenerate project if `project.yml` changed: `xcodegen generate --spec project.yml`
4. Deploy updated Firestore rules before merging: `firebase deploy --only firestore:rules,firestore:indexes`
5. All strings must use `L("string")` — no raw Arabic literals in components
6. New financial math belongs in an Engine, not in a View or Service

See [ARCHITECTURE.md](ARCHITECTURE.md) for system design and [SECURITY.md](SECURITY.md) for the security model.

---

## Simulator Log Noise

These messages appear in the Xcode console but are **iOS 26 simulator bugs**, not app issues. They do not appear on a real device.

| Message | Cause |
|---|---|
| `hapticpatternlibrary.plist not found` | iOS 26.3 simulator runtime missing haptic asset files |
| `AppleColorEmoji.ttc not found` | iOS 26.3 simulator runtime missing emoji font |
| `Unable to simultaneously satisfy constraints (accessoryView.bottom / inputView.top)` | UIKit keyboard layout conflict in iOS 26 — auto-recovers |
| `RTIInputSystemClient requires valid sessionID` | Text input system noise — simulator only |
| `Result accumulator timeout: 0.250000` | Autocomplete timeout — simulator only |
