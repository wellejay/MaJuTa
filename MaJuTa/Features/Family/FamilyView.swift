import SwiftUI

struct FamilyView: View {
    @EnvironmentObject var dataStore: DataStore
    @ObservedObject private var userService = UserService.shared

    // Invite
    @State private var showInviteSheet = false
    @State private var inviteCode = ""
    @State private var codeCopied = false

    // Join
    @State private var showJoinSheet = false
    @State private var joinCodeInput = ""
    @State private var joinCodeError = ""
    @State private var foundHousehold: RegisteredHousehold? = nil
    @State private var joinSuccess = false

    private var currentUser: UserProfile? { userService.currentUser }
    private var household: RegisteredHousehold? {
        guard let u = currentUser else { return nil }
        return userService.household(for: u)
    }
    private var members: [UserProfile] {
        guard let hh = household else { return [] }
        return userService.householdMembers(for: hh.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.md) {
                    householdCard
                    membersSection
                    inviteSection
                    joinSection
                    activitySection
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.vertical, MaJuTaSpacing.md)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle("العائلة")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showInviteSheet) {
            inviteCodeSheet
        }
        .sheet(isPresented: $showJoinSheet) {
            joinCodeSheet
        }
    }

    // MARK: - Household Card

    private var householdCard: some View {
        HStack(spacing: MaJuTaSpacing.md) {
            VStack(alignment: .trailing, spacing: 4) {
                Text(household?.name ?? "المنزل")
                    .font(.maJuTaBodyBold)
                    .foregroundColor(.maJuTaTextPrimary)
                Text("\(members.count) \(members.count == 1 ? "عضو" : "أعضاء")")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.maJuTaGold.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "house.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.maJuTaGold)
            }
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    // MARK: - Members

    private var membersSection: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            Text("الأعضاء")
                .font(.maJuTaSectionTitle)
                .foregroundColor(.maJuTaTextPrimary)

            VStack(spacing: 1) {
                ForEach(members) { member in
                    memberRow(member)
                    if member.id != members.last?.id { Divider() }
                }
            }
            .background(Color.maJuTaCard)
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            .maJuTaCardShadow()
        }
    }

    @ViewBuilder
    private func memberRow(_ member: UserProfile) -> some View {
        let isCurrentOwner = currentUser?.role == .owner
        let isOtherMember = member.id != currentUser?.id

        VStack(spacing: 0) {
            HStack(spacing: MaJuTaSpacing.md) {
                // Actions for owner on non-self members
                if isCurrentOwner && isOtherMember {
                    Button {
                        removeMember(member)
                    } label: {
                        Image(systemName: "person.fill.xmark")
                            .font(.system(size: 14))
                            .foregroundColor(.maJuTaNegative)
                    }
                } else if member.role == .owner {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.maJuTaGold)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 6) {
                        if member.id == currentUser?.id {
                            Text("أنت")
                                .font(.maJuTaLabel)
                                .foregroundColor(.maJuTaGold)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.maJuTaGold.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        Text(member.name)
                            .font(.maJuTaBody)
                            .foregroundColor(.maJuTaTextPrimary)
                    }
                    // Role picker for owner editing other members
                    if isCurrentOwner && isOtherMember {
                        Menu {
                            ForEach([UserRole.admin, .member, .viewOnly], id: \.self) { role in
                                Button(role.displayName) {
                                    userService.updateRole(role, for: member.id)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(member.role.displayName)
                                    .font(.maJuTaLabel)
                                    .foregroundColor(.maJuTaGold)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.maJuTaGold)
                            }
                        }
                    } else {
                        Text(member.role.displayName)
                            .font(.maJuTaLabel)
                            .foregroundColor(.maJuTaTextSecondary)
                    }
                }

                Spacer()

                Circle()
                    .fill(Color(hex: member.avatarColorHex).opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(member.name.prefix(1)).uppercased())
                            .font(.maJuTaBodyBold)
                            .foregroundColor(Color(hex: member.avatarColorHex))
                    )
            }
            .padding(MaJuTaSpacing.md)
            .background(Color.maJuTaCard)
        }
    }

    private func removeMember(_ member: UserProfile) {
        userService.removeMember(member.id)
    }

    // MARK: - Invite Button

    private var inviteSection: some View {
        Button {
            if let hh = household {
                inviteCode = userService.generateInviteCode(for: hh.id)
                showInviteSheet = true
            }
        } label: {
            HStack(spacing: MaJuTaSpacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.maJuTaGold)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("دعوة أعضاء العائلة")
                        .font(.maJuTaBodyBold)
                        .foregroundColor(.maJuTaTextPrimary)
                    Text("شارك كود الدعوة مع أفراد عائلتك")
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                }
                Circle()
                    .fill(Color.maJuTaGold.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18))
                            .foregroundColor(.maJuTaGold)
                    )
            }
            .padding(MaJuTaSpacing.lg)
            .background(Color.maJuTaCard)
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            .maJuTaCardShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Join Button

    private var joinSection: some View {
        Button {
            joinCodeInput = ""
            joinCodeError = ""
            foundHousehold = nil
            showJoinSheet = true
        } label: {
            HStack(spacing: MaJuTaSpacing.md) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("الانضمام لعائلة موجودة")
                        .font(.maJuTaBodyBold)
                        .foregroundColor(.maJuTaTextPrimary)
                    Text("أدخل كود الدعوة من صاحب الحساب")
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                }
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.2.badge.key.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    )
            }
            .padding(MaJuTaSpacing.lg)
            .background(Color.maJuTaCard)
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            .maJuTaCardShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Invite Code Sheet

    private var inviteCodeSheet: some View {
        VStack(spacing: MaJuTaSpacing.xl) {
            VStack(spacing: MaJuTaSpacing.sm) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.maJuTaGold)
                Text("كود الدعوة")
                    .font(.maJuTaTitle2)
                    .foregroundColor(.maJuTaTextPrimary)
                Text("شارك هذا الكود مع أفراد عائلتك")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Code display — dark text on light background for clear visibility
            Text(inviteCode.isEmpty ? "------" : inviteCode)
                .font(.system(size: 52, weight: .bold, design: .monospaced))
                .foregroundColor(.maJuTaPrimary)
                .tracking(8)
                .padding(.vertical, MaJuTaSpacing.lg)
                .padding(.horizontal, MaJuTaSpacing.xl)
                .background(Color.maJuTaGold.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))

            Text("عند التسجيل، يختار العضو \"انضم لعائلة موجودة\" ويدخل هذا الكود\nأو يضغط \"الانضمام لعائلة موجودة\" من صفحة العائلة")
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                UIPasteboard.general.string = inviteCode
                codeCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { codeCopied = false }
            } label: {
                Label(codeCopied ? "تم النسخ ✓" : "نسخ الكود", systemImage: codeCopied ? "checkmark" : "doc.on.doc")
                    .font(.maJuTaBodyBold)
                    .foregroundColor(.maJuTaPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(codeCopied ? Color.maJuTaPositive : Color.maJuTaGold)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                    .animation(.spring(), value: codeCopied)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top, MaJuTaSpacing.xl)
        .presentationDetents([.medium])
        .background(Color.maJuTaBackground.ignoresSafeArea())
    }

    // MARK: - Join Code Sheet

    private var joinCodeSheet: some View {
        VStack(spacing: MaJuTaSpacing.xl) {
            VStack(spacing: MaJuTaSpacing.sm) {
                Image(systemName: "person.2.badge.key.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                Text("الانضمام لعائلة")
                    .font(.maJuTaTitle2)
                    .foregroundColor(.maJuTaTextPrimary)
                Text("أدخل كود الدعوة المكون من 6 أرقام")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
                    .multilineTextAlignment(.center)
            }

            // Code input
            TextField("", text: $joinCodeInput,
                prompt: Text("000000").foregroundColor(.maJuTaTextSecondary))
                .keyboardType(.numberPad)
                .font(.system(size: 44, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .tracking(8)
                .foregroundColor(.maJuTaTextPrimary)
                .frame(height: 72)
                .padding(.horizontal, MaJuTaSpacing.md)
                .background(Color.maJuTaBackground)
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: MaJuTaRadius.card)
                        .stroke(joinCodeInput.count == 6 ? Color.maJuTaGold : Color.maJuTaTextSecondary.opacity(0.3), lineWidth: 2)
                )
                .onChange(of: joinCodeInput) { _, v in
                    joinCodeInput = String(v.filter { $0.isNumber }.prefix(6))
                    if joinCodeInput.count == 6 {
                        checkCode()
                    } else {
                        foundHousehold = nil
                        joinCodeError = ""
                    }
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)

            // Error / found household
            if !joinCodeError.isEmpty {
                Label(joinCodeError, systemImage: "xmark.circle.fill")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaNegative)
            } else if let hh = foundHousehold {
                VStack(spacing: 6) {
                    Label("تم العثور على العائلة!", systemImage: "checkmark.circle.fill")
                        .font(.maJuTaCaptionMedium)
                        .foregroundColor(.maJuTaPositive)
                    Text(hh.name)
                        .font(.maJuTaBodyBold)
                        .foregroundColor(.maJuTaTextPrimary)
                    let count = userService.householdMembers(for: hh.id).count
                    Text("\(count) \(count == 1 ? "عضو" : "أعضاء") حالياً")
                        .font(.maJuTaCaption)
                        .foregroundColor(.maJuTaTextSecondary)
                }
                .padding(MaJuTaSpacing.md)
                .background(Color.maJuTaPositive.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            }

            // Confirm join button
            if foundHousehold != nil {
                Button {
                    confirmJoin()
                } label: {
                    Text("انضم الآن")
                        .font(.maJuTaBodyBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top, MaJuTaSpacing.xl)
        .presentationDetents([.medium, .large])
        .background(Color.maJuTaBackground.ignoresSafeArea())
    }

    // MARK: - Join Logic

    private func checkCode() {
        if let hh = userService.findHousehold(byCode: joinCodeInput) {
            // Don't let user join their own household
            if hh.id == household?.id {
                joinCodeError = "أنت بالفعل عضو في هذه العائلة"
                foundHousehold = nil
            } else {
                foundHousehold = hh
                joinCodeError = ""
            }
        } else {
            joinCodeError = "كود الدعوة غير صحيح، تحقق وأعد المحاولة"
            foundHousehold = nil
        }
    }

    private func confirmJoin() {
        guard let hh = foundHousehold, let user = currentUser else { return }
        userService.joinHousehold(hh, userId: user.id)
        DataStore.shared.loadForCurrentUser()
        showJoinSheet = false
        joinSuccess = true
    }

    // MARK: - Activity Log

    private var activitySection: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
            Text("سجل النشاط")
                .font(.maJuTaSectionTitle)
                .foregroundColor(.maJuTaTextPrimary)

            if dataStore.activityLog.isEmpty {
                Text("لا يوجد نشاط بعد")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(MaJuTaSpacing.lg)
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            } else {
                VStack(spacing: 1) {
                    ForEach(dataStore.activityLog.prefix(10)) { entry in
                        HStack(spacing: MaJuTaSpacing.sm) {
                            Text(entry.timestamp.shortFormatted)
                                .font(.maJuTaLabel)
                                .foregroundColor(.maJuTaTextSecondary)
                            Spacer()
                            Text("\(entry.userName) \(entry.actionType.arabicDescription)")
                                .font(.maJuTaCaption)
                                .foregroundColor(.maJuTaTextPrimary)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(MaJuTaSpacing.md)
                        .background(Color.maJuTaCard)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                .maJuTaCardShadow()
            }
        }
    }
}
