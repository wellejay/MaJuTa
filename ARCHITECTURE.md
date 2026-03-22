# MaJuTa — Architecture Reference

## Overview

MaJuTa uses **MVVM + Service-Oriented Architecture** on SwiftUI with Firebase as the backend. Views consume observable services via `@EnvironmentObject` and `@ObservedObject`. All business logic lives in stateless Engines. All I/O goes through Services.

---

## Layer Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        SwiftUI Views                         │
│              Features/ — @State, @Binding, .sheet            │
└───────────────────────┬─────────────────────────────────────┘
                        │ @EnvironmentObject / @ObservedObject
┌───────────────────────▼─────────────────────────────────────┐
│                   Observable Services                         │
│                                                              │
│  AppState              global UI state, color scheme, lang   │
│  AuthenticationService biometric/passcode gate               │
│  UserService           registration, PIN, Keychain, roles    │
│  FirebaseAuthService   Firebase Auth: create, sign in, verify│
│  DataStore             8 Firestore listeners, computed values │
│  FirestoreService      generic Firestore CRUD + listeners    │
└───────────────────────┬─────────────────────────────────────┘
                        │ pure functions, no state
┌───────────────────────▼─────────────────────────────────────┐
│                     Business Logic Engines                    │
│                                                              │
│  CashFlowEngine        income/expense/safeToSpend math       │
│  FinancialHealthEngine 4-component health score (0–100)      │
│  InvestmentEngine      portfolio value, P&L, allocation      │
│  ZakatEngine           Islamic Zakat calculation             │
│  LedgerEngine          ledger reconciliation                 │
└───────────────────────┬─────────────────────────────────────┘
                        │ Codable structs
┌───────────────────────▼─────────────────────────────────────┐
│                        Data Models                           │
│  Transaction, Account, Bill, SavingsGoal, Investment,        │
│  InstallmentPlan, Loan, Budget, ActivityEntry, UserProfile   │
└─────────────────────────────────────────────────────────────┘
```

---

## Service Dependency Graph

```
MaJuTaApp (@main)
  ├── AppState
  ├── AuthenticationService
  │     └── UserService.shared
  │           ├── KeychainService
  │           └── FirebaseAuthService.shared
  │                 └── Firebase Auth SDK
  └── DataStore.shared
        └── FirestoreService.shared
              └── Firestore SDK
```

Services are singletons (`static let shared`) injected into views via `.environmentObject()`.

---

## Data Flow

### Read path (real-time)
```
Firestore ──snapshot listener──► FirestoreService ──onChange──► DataStore.@Published arrays
                                                                       │
                                                             computed properties
                                                                       │
                                                              SwiftUI Views (auto-refresh)
```

### Write path (optimistic)
```
View action
    │
DataStore mutation method (e.g. addTransaction)
    ├── mutate local @Published array immediately    ← UI updates instantly
    └── FirestoreService.save(document)             ← fire-and-forget, no await
              │
           Firestore
              │
        snapshot fires back
              │
       DataStore.@Published updated again (confirms or corrects)
```

> **Known limitation:** Concurrent offline mutations to `account.balance` use last-write-wins. Use `FieldValue.increment()` for atomic balance updates in a future improvement.

---

## Firestore Schema

```
/authLookup/{firebaseUID}
    userId: String           # app-layer UUID
    householdId: String      # app-layer UUID

/users/{userId}
    id, name, username, email, phoneNumber
    householdId, role, avatarColorHex, firebaseUID, createdAt

/households/{householdId}
    id, name, ownerUserId, createdAt

/households/{householdId}/accounts/{id}
    id, name, type, balance, currency, ownerUserId, householdId
    isShared, isLiquid, createdAt, updatedAt

/households/{householdId}/transactions/{id}
    id, amount, categoryId, accountId, date, merchant
    paymentMethod, notes, isRecurring, ownerUserId, createdByUserId
    householdId, syncStatus, createdAt

/households/{householdId}/savingsGoals/{id}
    id, name, targetAmount, currentAmount, deadline
    isShared, ownerUserId, householdId, createdAt

/households/{householdId}/bills/{id}
    id, name, nameArabic, amount, dueDate, frequency
    status, accountId, ownerUserId, provider, householdId

/households/{householdId}/investments/{id}
    id, symbol, name, units, costBasis, lastPrice
    assetType, market, ownerUserId, householdId, updatedAt

/households/{householdId}/installmentPlans/{id}
    id, merchant, provider, totalAmount, installmentsCount
    ownerUserId, householdId, createdAt

/households/{householdId}/installments/{id}
    id, planId, dueDate, amount, status, ownerUserId, householdId

/households/{householdId}/activityLog/{id}
    id, userId, userName, actionType, timestamp, householdId
    (immutable — no client-side update/delete)

/households/{householdId}/budgets/{id}
    id, categoryId, plannedAmount, period, ownerUserId, householdId

/inviteCodes/{code}
    householdId, createdAt, expiresAt (optional)

/authLogs/{logId}
    uid, userId, event, timestamp
    (write-only from client — read via Firebase console)
```

### Key design decisions
- All financial data scoped under `households/{id}` — no cross-household reads possible
- `authLookup` is the security-rule bridge: maps Firebase UID → householdId without embedding it in the auth token
- `authLookup` is immutable after creation (`update/delete: false` in rules)
- Activity log is client-capped at 100 in memory; Firestore collection grows unboundedly (cap with Cloud Function)

---

## Authentication Flow

```
App Launch
    │
    ├─► No registered users → WelcomeGateView
    │       ├─ Create Account → RegistrationView
    │       └─ Browse as Guest → guest mode (local JSON, no Firebase)
    │
    └─► Users exist
            │
            ▼
        UserPickerView
            │
            ▼
        AuthenticationService.authenticate()
            ├─ LAContext biometric (Face ID / Touch ID)
            └─ LAContext device passcode (fallback)
                    │
                    ▼ success
            UserService.setCurrentUser(user)
            UserService.signInToFirebase(user, pin)
                    │
                    ├─ Recompute: SHA256("fb_<pin>_<uuid>_majuta") → Firebase password
                    ├─ Auth.auth().signIn(email, password)
                    └─ syncFromFirestore() → update household members
                    │
                    ▼
            DataStore.loadForCurrentUser()
                    └─ Attach 8 Firestore snapshot listeners
                    │
                    ▼
            MainTabView (or OnboardingView if first launch)
```

---

## Design System

Located in `MaJuTa/DesignSystem/`.

### Tokens

| File | Contents |
|---|---|
| `MaJuTaColors.swift` | Brand colors, semantic colors, adaptive backgrounds (UIColor dynamic provider), tint backgrounds, border, gradients |
| `MaJuTaTypography.swift` | Font scale: hero (40pt) → label (11pt). `maJuTaButton` for CTAs |
| `MaJuTaSpacing.swift` | 8pt grid (xs–xxxl), semantic aliases (hairline, tight, iconBadge, pinButtonSize), corner radius |
| `MaJuTaIcons.swift` | SF Symbol names for categories, payment methods, navigation, actions. Uses `chevron.forward/backward` for RTL auto-mirroring |

### Key Components

| Component | Purpose |
|---|---|
| `SARText` | Renders Saudi Riyal amounts with custom riyal glyph font + VoiceOver label |
| `EmptyStateView` | Reusable empty-state placeholder with accessibility built in |
| `TransactionRowView` | List row for transactions |
| `BillRowView` | List row for bills (embedded in TransactionRowView.swift) |

### Color Token Rules
- **Never use raw hex** in feature views — always use a named token
- **Semantic tint backgrounds** (`maJuTaPositiveBg`, `maJuTaNegativeBg`, `maJuTaWarningBg`, `maJuTaInfoBg`) replace `.opacity(0.08/.15)` inline hacks
- **`LinearGradient.emergencyGradient`** is the single source for the red gradient used in emergency fund views

---

## Localization

```
Resources/
  ar.lproj/Localizable.strings   (empty — Arabic keys are the strings)
  en.lproj/Localizable.strings   (English translations)

Core/Localization/L.swift        (L() helper function)
```

The `L()` function performs runtime bundle lookup with zero overhead for Arabic (no lookup needed — the key is the string). Language switching via `AppState.appLanguage` (@AppStorage) rebuilds the view tree via `.id(appState.appLanguage)`.

---

## Build System

- **XcodeGen** generates `MaJuTa.xcodeproj` from `project.yml`
- **Swift Package Manager** resolves Firebase iOS SDK 11.0.0+
- Never edit `.xcodeproj` directly — regenerate with `xcodegen generate --spec project.yml`
- `Package.resolved` should be committed to lock Firebase SDK versions

---

## Testing

Tests live in `MaJuTaTests/MajuliaTests.swift`. All 21 tests cover financial engine logic:
- Net cash flow, safe-to-spend, emergency months, savings rate
- Investment portfolio value
- Financial health score grades (excellent, fair, poor)
- Obligation risk boundaries (0.40, 0.60)
- Edge cases: zero income, zero essentials, negative net worth, empty arrays

Run tests: `Cmd+U` in Xcode, or via CI: `xcodebuild test -scheme MaJuTa ...`

---

## Known Architectural Limitations

| Area | Issue | Recommendation |
|---|---|---|
| DataStore | ~900 lines, 3 responsibilities | Split into GuestDataManager, FinancialComputedStore, HouseholdRepository |
| UserService | ~460 lines, 4 responsibility clusters | Split into Auth/Registration/Household/Profile services |
| Account balance | Last-write-wins on concurrent offline edits | Use `FieldValue.increment()` for atomic updates |
| Bill + transaction writes | Two separate non-atomic Firestore calls | Use `WriteBatch` |
| Activity log cap | Client-side trim only — Firestore grows unboundedly | Add `.limit(100)` query + Cloud Function TTL |
| CoreData | Configured but unused | Remove or wire up for offline-first editing |
| Keychain reads at startup | Synchronous on `@MainActor` — can block 20–100ms | Move to background task |
