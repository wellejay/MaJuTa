import SwiftUI
import LocalAuthentication

struct RegistrationView: View {
    @EnvironmentObject var authService: AuthenticationService

    // MARK: - State
    @State private var step: RegistrationStep = .name
    @State private var name          = ""
    @State private var username      = ""
    @State private var email         = ""
    @State private var pin           = ""
    @State private var confirmPin    = ""
    @State private var pinError      = ""
    @State private var fieldError    = ""

    // Household join
    @State private var joinCodeInput      = ""
    @State private var joinCodeError      = ""
    @State private var joiningHousehold: RegisteredHousehold? = nil

    // Biometric
    @State private var pendingUser: UserProfile? = nil
    @State private var biometricError = ""

    // Async registration state
    @State private var isRegistering = false

    enum RegistrationStep {
        case name, username, email
        case householdChoice, joinCode
        case pin, confirmPin, biometric
    }

    // Total visible steps for progress (name/username/email/pin/confirmPin/biometric = 6)
    private var totalSteps: Int { 6 }
    private var currentStepIndex: Int {
        switch step {
        case .name:             return 1
        case .username:         return 2
        case .email:            return 3
        case .householdChoice,
             .joinCode:         return 3   // sub-steps, no progress advance
        case .pin:              return 4
        case .confirmPin:       return 5
        case .biometric:        return 6
        }
    }

    var body: some View {
        ZStack {
            LinearGradient.navyGradient.ignoresSafeArea()
            VStack(spacing: 0) {
                // Top bar: back button + logo
                ZStack(alignment: .leading) {
                    // Back button: goes to previous step, or cancels registration on first step
                    if step != .biometric {
                        Button(action: {
                            if step == .name {
                                authService.showRegistration = false
                            } else {
                                previousStep()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(step == .name ? L("إلغاء") : L("رجوع"))
                                    .font(.maJuTaCaptionMedium)
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.leading, MaJuTaSpacing.horizontalPadding)
                    }

                    // Logo centred
                    HStack {
                        Spacer()
                        Image("MaJuTaLogo")
                            .resizable().scaledToFit().frame(width: 120)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.white.opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Spacer()
                    }
                }
                .padding(.top, 56)

                // Progress bar
                progressBar
                    .padding(.top, MaJuTaSpacing.md)

                Spacer()

                // Step content
                VStack(spacing: MaJuTaSpacing.lg) {
                    switch step {
                    case .name:          nameStep
                    case .username:      usernameStep
                    case .email:         emailStep
                    case .householdChoice: householdChoiceStep
                    case .joinCode:      joinCodeStep
                    case .pin:           pinInputStep(title: L("اختر رمز مرور من 6 أرقام"),
                                                     subtitle: L("سيُستخدم لتأمين حسابك"), binding: $pin)
                    case .confirmPin:    pinInputStep(title: L("تأكيد رمز المرور"),
                                                     subtitle: L("أعد إدخال الرقم السري"), binding: $confirmPin)
                    case .biometric:     biometricStep
                    }

                    if !pinError.isEmpty && (step == .pin || step == .confirmPin) {
                        Text(pinError).font(.maJuTaCaption).foregroundColor(.maJuTaNegative)
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)

                Spacer()
            }

            // Loading overlay during async registration
            if isRegistering {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStepIndex ? Color.maJuTaGold : Color.white.opacity(0.25))
                    .frame(height: 4)
                    .animation(.spring(), value: currentStepIndex)
            }
        }
        .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
    }

    // MARK: - Step 1: Name
    private var nameStep: some View {
        VStack(spacing: MaJuTaSpacing.lg) {
            stepTitle(L("ما اسمك الكامل؟"), subtitle: L("سيظهر هذا للأعضاء الآخرين"))
            styledField(L("الاسم الكامل"), text: $name, keyboardType: .default)
            primaryButton(L("التالي"), disabled: name.trimmingCharacters(in: .whitespaces).count < 2) {
                fieldError = ""
                step = .username
            }
        }
    }

    // MARK: - Step 2: Username
    private var usernameStep: some View {
        VStack(spacing: MaJuTaSpacing.lg) {
            stepTitle(L("اختر اسم المستخدم"), subtitle: L("يجب أن يكون فريداً · حروف وأرقام فقط"))
            HStack {
                styledField(L("مثال: waleed_99"), text: $username, keyboardType: .asciiCapable)
                Text("@").font(.maJuTaTitle2).foregroundColor(.maJuTaGold)
            }
            if !fieldError.isEmpty {
                Text(fieldError).font(.maJuTaCaption).foregroundColor(.maJuTaNegative)
            }
            primaryButton(L("التالي"), disabled: username.count < 3) {
                let trimmed = cleanString(username)
                if !isValidUsername(trimmed) {
                    fieldError = L("يجب أن يحتوي على 3–20 حرفاً (a-z 0-9 _) فقط")
                } else if !UserService.shared.isUsernameAvailable(trimmed) {
                    fieldError = L("اسم المستخدم مستخدم بالفعل، اختر آخر")
                } else {
                    fieldError = ""
                    username = trimmed
                    step = .email
                }
            }
        }
    }

    // MARK: - Step 3: Email
    private var emailStep: some View {
        VStack(spacing: MaJuTaSpacing.lg) {
            stepTitle(L("بريدك الإلكتروني"), subtitle: L("مطلوب بريد إلكتروني حقيقي"))
            styledField("example@email.com", text: $email, keyboardType: .emailAddress)
            if !fieldError.isEmpty {
                Text(fieldError).font(.maJuTaCaption).foregroundColor(.maJuTaNegative)
            }
            primaryButton(L("التالي"), disabled: email.count < 5) {
                let cleaned = cleanString(email)
                if !isValidEmail(cleaned) {
                    fieldError = L("يرجى إدخال بريد إلكتروني حقيقي (مثال: name@gmail.com)")
                } else if !UserService.shared.isEmailAvailable(cleaned) {
                    fieldError = L("هذا البريد الإلكتروني مسجّل بالفعل في حساب آخر")
                } else {
                    fieldError = ""
                    email = cleaned
                    if !UserService.shared.registeredHouseholds.isEmpty {
                        step = .householdChoice
                    } else {
                        step = .pin
                    }
                }
            }
        }
    }

    // MARK: - Household Choice (conditional)
    private var householdChoiceStep: some View {
        VStack(spacing: MaJuTaSpacing.lg) {
            stepTitle(L("هل تنضم لعائلة موجودة؟"), subtitle: nil)
            VStack(spacing: MaJuTaSpacing.md) {
                Button {
                    joiningHousehold = nil
                    joinCodeInput = ""
                    joinCodeError = ""
                    step = .joinCode
                } label: {
                    HStack(spacing: MaJuTaSpacing.md) {
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(L("انضم لعائلة موجودة"))
                                .font(.maJuTaBodyBold).foregroundColor(.maJuTaPrimary)
                            Text(L("لديك كود دعوة من أحد أفراد العائلة"))
                                .font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 22)).foregroundColor(.maJuTaGold)
                    }
                    .padding(MaJuTaSpacing.lg)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                }
                Button {
                    joiningHousehold = nil
                    step = .pin
                } label: {
                    HStack(spacing: MaJuTaSpacing.md) {
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(L("أنشئ عائلة جديدة"))
                                .font(.maJuTaBodyBold).foregroundColor(.white)
                            Text(L("ابدأ حساباً منزلياً مستقلاً"))
                                .font(.maJuTaCaption).foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22)).foregroundColor(.maJuTaGold)
                    }
                    .padding(MaJuTaSpacing.lg)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                }
            }
        }
    }

    // MARK: - Join Code (conditional)
    private var joinCodeStep: some View {
        VStack(spacing: MaJuTaSpacing.lg) {
            stepTitle(L("أدخل كود الدعوة"), subtitle: L("اطلب الكود من صاحب الحساب المنزلي"))
            TextField("000000", text: $joinCodeInput)
                .keyboardType(.numberPad)
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundColor(.maJuTaPrimary)
                .frame(height: 72)
                .padding(.horizontal, MaJuTaSpacing.md)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                .onChange(of: joinCodeInput) { _, v in
                    joinCodeInput = String(v.filter(\.isNumber).prefix(6))
                }
            if !joinCodeError.isEmpty {
                Text(joinCodeError).font(.maJuTaCaption).foregroundColor(.maJuTaNegative)
            }
            primaryButton(L("تأكيد"), disabled: joinCodeInput.count != 6) {
                // Try local lookup first, then remote
                if let hh = UserService.shared.findHousehold(byCode: joinCodeInput) {
                    joiningHousehold = hh
                    joinCodeError = ""
                    step = .pin
                } else {
                    // Try remote Firestore lookup
                    Task {
                        if let hh = await UserService.shared.findHouseholdRemote(byCode: joinCodeInput) {
                            joiningHousehold = hh
                            joinCodeError = ""
                            step = .pin
                        } else {
                            joinCodeError = L("كود الدعوة غير صحيح، تحقق وأعد المحاولة")
                        }
                    }
                }
            }
            Button(L("رجوع")) { step = .householdChoice }
                .font(.maJuTaCaption).foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - PIN Input
    private func pinInputStep(title: String, subtitle: String, binding: Binding<String>) -> some View {
        VStack(spacing: MaJuTaSpacing.lg) {
            VStack(spacing: MaJuTaSpacing.sm) {
                if let hh = joiningHousehold, step == .pin {
                    Text(L("الانضمام إلى: \(hh.name)"))
                        .font(.maJuTaLabel).foregroundColor(.maJuTaGold)
                }
                Text(title).font(.maJuTaTitle2).foregroundColor(.white)
                Text(subtitle).font(.maJuTaCaption).foregroundColor(.white.opacity(0.7))
            }
            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i < binding.wrappedValue.count ? Color.maJuTaGold : Color.white.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
            PINPadView(pin: binding, maxDigits: 6) {
                handlePINEntry(binding.wrappedValue)
            }
        }
    }

    // MARK: - Biometric Step
    private var biometricStep: some View {
        VStack(spacing: MaJuTaSpacing.xl) {
            ZStack {
                Circle()
                    .fill(Color.maJuTaGold.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: biometricIcon)
                    .font(.system(size: 52))
                    .foregroundColor(.maJuTaGold)
            }
            VStack(spacing: MaJuTaSpacing.sm) {
                Text(L("تفعيل \(biometricLabel)"))
                    .font(.maJuTaTitle2).foregroundColor(.white)
                Text(L("استخدم \(biometricLabel) لتسجيل الدخول بسرعة وأمان بدلاً من رمز المرور في كل مرة"))
                    .font(.maJuTaCaption).foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            if !biometricError.isEmpty {
                Text(biometricError).font(.maJuTaCaption).foregroundColor(.maJuTaNegative)
            }
            primaryButton(L("تفعيل \(biometricLabel)"), disabled: false) {
                Task { await enrollBiometric() }
            }
            Button(L("تخطى")) { finishRegistration() }
                .font(.maJuTaCaptionMedium).foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Biometric helpers
    private var biometricType: LABiometryType {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return ctx.biometryType
    }
    private var biometricIcon: String {
        biometricType == .faceID ? "faceid" : "touchid"
    }
    private var biometricLabel: String {
        biometricType == .faceID ? "Face ID" : "Touch ID"
    }

    private func enrollBiometric() async {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricError = L("الجهاز لا يدعم \(biometricLabel)")
            return
        }
        do {
            let ok = try await ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: L("تحقق من هويتك لتفعيل الدخول بـ \(biometricLabel)")
            )
            if ok, let user = pendingUser {
                UserService.shared.setBiometricEnabled(for: user.id)
            }
            finishRegistration()
        } catch {
            biometricError = L("فشل تفعيل \(biometricLabel)، يمكنك تخطي هذه الخطوة")
        }
    }

    // MARK: - PIN Logic
    private func handlePINEntry(_ entered: String) {
        guard entered.count == 6 else { return }
        switch step {
        case .pin:
            pin = entered
            confirmPin = ""
            pinError = ""
            step = .confirmPin
        case .confirmPin:
            if entered == pin {
                // Create the user profile — async because Firebase Auth is involved
                isRegistering = true
                Task {
                    let user: UserProfile
                    if let hh = joiningHousehold {
                        user = await UserService.shared.addMember(
                            name: name.trimmingCharacters(in: .whitespaces),
                            username: username,
                            email: email,
                            phoneNumber: "",
                            pin: pin,
                            to: hh
                        )
                    } else {
                        user = await UserService.shared.register(
                            name: name.trimmingCharacters(in: .whitespaces),
                            username: username,
                            email: email,
                            phoneNumber: "",
                            pin: pin
                        )
                    }
                    pendingUser = user
                    UserService.shared.setCurrentUser(user)
                    DataStore.shared.loadForCurrentUser()
                    isRegistering = false
                    // Continue to biometric or finish
                    let ctx = LAContext()
                    if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                        step = .biometric
                    } else {
                        finishRegistration()
                    }
                }
            } else {
                pinError = L("الرمز غير متطابق، حاول مجدداً")
                confirmPin = ""
                pin = ""
                step = .pin
            }
        default:
            break
        }
    }

    private func previousStep() {
        fieldError = ""
        pinError = ""
        switch step {
        case .name:            break
        case .username:        step = .name
        case .email:           step = .username
        case .householdChoice: step = .email
        case .joinCode:        step = .householdChoice
        case .pin:
            if !UserService.shared.registeredHouseholds.isEmpty {
                step = .householdChoice
            } else {
                step = .email
            }
        case .confirmPin:
            pin = ""
            confirmPin = ""
            step = .pin
        case .biometric:       break
        }
    }

    private func finishRegistration() {
        authService.showRegistration = false
        // Show email verification screen unless Firebase already verified the email
        if FirebaseAuthService.shared.isEmailVerified {
            authService.isAuthenticated = true
        } else {
            authService.showEmailVerification = true
        }
    }

    // MARK: - Reusable UI
    private func stepTitle(_ title: String, subtitle: String?) -> some View {
        VStack(spacing: MaJuTaSpacing.xs) {
            Text(title).font(.maJuTaTitle2).foregroundColor(.white).multilineTextAlignment(.center)
            if let sub = subtitle {
                Text(sub).font(.maJuTaCaption).foregroundColor(.white.opacity(0.65)).multilineTextAlignment(.center)
            }
        }
    }

    private func styledField(_ placeholder: String, text: Binding<String>,
                              keyboardType: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboardType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .font(.maJuTaBody)
            .foregroundColor(.maJuTaPrimary)
            .multilineTextAlignment(.trailing)
            .padding(MaJuTaSpacing.md)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.input))
    }

    private func primaryButton(_ label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.maJuTaBodyBold)
                .foregroundColor(disabled ? .white.opacity(0.5) : .maJuTaPrimary)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(disabled ? Color.white.opacity(0.2) : Color.maJuTaGold)
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
        }
        .disabled(disabled)
    }

    // MARK: - Validators

    /// Strip invisible Unicode direction marks iOS injects in RTL text fields
    private func cleanString(_ s: String) -> String {
        let directionMarks = CharacterSet(charactersIn: "\u{200F}\u{200E}\u{202A}\u{202B}\u{202C}\u{202D}\u{202E}\u{FEFF}")
        return s.unicodeScalars
            .filter { !directionMarks.contains($0) }
            .reduce("") { $0 + String($1) }
            .trimmingCharacters(in: .whitespaces)
    }

    private func isValidEmail(_ s: String) -> Bool {
        let clean = cleanString(s)
        // Strict format: real chars before @, valid domain, letter-only TLD >= 2
        let pattern = #"^[a-zA-Z0-9._%+\-]{2,}@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$"#
        guard clean.range(of: pattern, options: .regularExpression) != nil else { return false }

        // Extract domain and TLD
        let parts = clean.components(separatedBy: "@")
        guard parts.count == 2 else { return false }
        let domain = parts[1].lowercased()
        let tld = domain.components(separatedBy: ".").last ?? ""

        // Block fake/test/disposable TLDs
        let fakeTLDs: Set<String> = ["test", "fake", "invalid", "example",
                                     "localhost", "local", "internal", "dummy"]
        guard !fakeTLDs.contains(tld) else { return false }

        // Block well-known disposable/fake email domains
        let blockedDomains: Set<String> = [
            "mailinator.com", "guerrillamail.com", "sharklasers.com", "yopmail.com",
            "trashmail.com", "tempmail.com", "throwaway.com", "dispostable.com",
            "fakeinbox.com", "maildrop.cc", "spamgourmet.com", "test.com",
            "fake.com", "fake.net", "example.com", "example.net", "example.org",
            "testing.com", "dummy.com", "noemail.com", "notanemail.com"
        ]
        guard !blockedDomains.contains(domain) else { return false }

        return true
    }

    private func isValidUsername(_ s: String) -> Bool {
        let pattern = #"^[a-zA-Z0-9_]{3,20}$"#
        return s.range(of: pattern, options: .regularExpression) != nil
    }
}
