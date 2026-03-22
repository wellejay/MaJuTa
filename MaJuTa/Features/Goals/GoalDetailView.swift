import SwiftUI

struct GoalDetailView: View {
    let goal: SavingsGoal
    @EnvironmentObject var dataStore: DataStore
    @State private var showContribute = false
    @State private var contributionAmount = ""

    /// Always reflects the latest state from DataStore after contributions.
    private var currentGoal: SavingsGoal {
        dataStore.visibleGoals.first { $0.id == goal.id } ?? goal
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MaJuTaSpacing.lg) {
                // Hero
                heroSection

                // Stats Grid
                statsGrid

                // Progress
                progressSection

                // Contribute Button
                Button {
                    showContribute = true
                } label: {
                    Label(L("إضافة مبلغ"), systemImage: "plus.circle.fill")
                        .font(.maJuTaBodyBold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.maJuTaPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                }
                .accessibilityLabel(L("إضافة مبلغ لهدف \(currentGoal.nameArabic.isEmpty ? currentGoal.name : currentGoal.nameArabic)"))
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
            .padding(.vertical, MaJuTaSpacing.lg)
        }
        .background(Color.maJuTaBackground)
        .navigationTitle(currentGoal.nameArabic.isEmpty ? currentGoal.name : currentGoal.nameArabic)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showContribute) {
            contributeSheet
        }
    }

    private var heroSection: some View {
        VStack(spacing: MaJuTaSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color(hex: currentGoal.colorHex).opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: currentGoal.icon)
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: currentGoal.colorHex))
            }

            SARText.hero(currentGoal.currentAmount)
                .accessibilityLabel(L("المبلغ المدخر: \(String(format: "%.0f", currentGoal.currentAmount)) ريال سعودي"))

            HStack(spacing: 2) {
                Text(L("من")).font(.maJuTaBody).foregroundColor(.maJuTaTextSecondary)
                SARText.body(currentGoal.targetAmount, color: .maJuTaTextSecondary)
            }
            .accessibilityLabel(L("المستهدف: \(String(format: "%.0f", currentGoal.targetAmount)) ريال سعودي"))
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var statsGrid: some View {
        HStack(spacing: MaJuTaSpacing.sm) {
            statItem(value: "\(currentGoal.progressPercentage)%", label: L("مكتمل"))
            VStack(spacing: 4) {
                SARText.compact(currentGoal.remainingAmount)
                Text(L("المتبقي"))
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(MaJuTaSpacing.md)
            .background(Color.maJuTaCard)
            .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
            .maJuTaCardShadow()
            if let deadline = currentGoal.deadline {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
                statItem(value: "\(max(0, days))", label: L("يوماً متبقياً"))
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.maJuTaMediumNumber)
                .foregroundColor(.maJuTaTextPrimary)
            Text(label)
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.md)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var progressSection: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            Text(L("تقدم الهدف"))
                .font(.maJuTaSectionTitle)
                .foregroundColor(.maJuTaTextPrimary)

            GeometryReader { geo in
                ZStack(alignment: .trailing) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.maJuTaBackground)
                        .frame(height: 16)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(
                            colors: [Color(hex: currentGoal.colorHex), Color(hex: currentGoal.colorHex).opacity(0.6)],
                            startPoint: .trailing,
                            endPoint: .leading
                        ))
                        .frame(width: geo.size.width * currentGoal.progress, height: 16)
                }
            }
            .frame(height: 16)
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var contributeSheet: some View {
        NavigationStack {
            VStack(spacing: MaJuTaSpacing.lg) {
                Text(L("إضافة مبلغ للهدف"))
                    .font(.maJuTaTitle2)

                HStack {
                    Text("\u{E900}")
                        .font(.custom(maJuTaRiyalFontName, size: 28))
                        .foregroundColor(.maJuTaTextSecondary)
                    TextField("0", text: $contributionAmount)
                        .keyboardType(.numberPad)
                        .font(.maJuTaHero)
                        .multilineTextAlignment(.trailing)
                }
                .padding(MaJuTaSpacing.lg)
                .background(Color.maJuTaCard)
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))

                Spacer()

                Button(L("إضافة")) {
                    if let amount = contributionAmount.arabicNormalizedDouble, amount > 0 {
                        dataStore.contribute(to: currentGoal, amount: amount)
                        contributionAmount = ""
                    }
                    showContribute = false
                }
                .font(.maJuTaBodyBold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.maJuTaPrimary)
                .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                .accessibilityLabel(L("إضافة المبلغ للهدف"))
            }
            .padding(MaJuTaSpacing.horizontalPadding)
            .navigationTitle(L("إضافة مدخرات"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Add Goal View
struct AddGoalView: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var targetAmount = ""
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var selectedIcon = "target"
    @State private var selectedColor = "#F2AE2E"

    let icons = ["target", "house.fill", "airplane", "car.fill", "graduationcap.fill",
                 "heart.fill", "gamecontroller.fill", "laptopcomputer", "camera.fill", "gift.fill"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.lg) {
                    // Icon & Name
                    VStack(spacing: MaJuTaSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: selectedColor).opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: selectedIcon)
                                .font(.system(size: 28))
                                .foregroundColor(Color(hex: selectedColor))
                        }

                        TextField(L("اسم الهدف"), text: $name)
                            .font(.maJuTaTitle2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.maJuTaTextPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(MaJuTaSpacing.lg)
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    .maJuTaCardShadow()

                    // Target Amount
                    HStack {
                        TextField("0", text: $targetAmount)
                            .keyboardType(.numberPad)
                            .font(.maJuTaLargeNumber)
                            .multilineTextAlignment(.trailing)
                        Text(L("المبلغ المستهدف (ر.س)"))
                            .font(.maJuTaCaption)
                            .foregroundColor(.maJuTaTextSecondary)
                    }
                    .padding(MaJuTaSpacing.md)
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    .maJuTaCardShadow()

                    // Deadline
                    VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
                        Toggle(L("تحديد موعد نهائي"), isOn: $hasDeadline)
                            .font(.maJuTaBody)
                            .tint(.maJuTaGold)
                        if hasDeadline {
                            DatePicker("", selection: $deadline, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "en_SA"))
                        }
                    }
                    .padding(MaJuTaSpacing.md)
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    .maJuTaCardShadow()

                    // Icons
                    VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
                        Text(L("اختر أيقونة"))
                            .font(.maJuTaCaption)
                            .foregroundColor(.maJuTaTextSecondary)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: MaJuTaSpacing.sm) {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedIcon == icon ? Color(hex: selectedColor) : .maJuTaTextSecondary)
                                        .frame(width: 44, height: 44)
                                        .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.15) : Color.maJuTaBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.small))
                                }
                            }
                        }
                    }
                    .padding(MaJuTaSpacing.md)
                    .background(Color.maJuTaCard)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
                    .maJuTaCardShadow()

                    Button(L("إنشاء الهدف")) {
                        saveGoal()
                    }
                    .font(.maJuTaBodyBold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(name.isEmpty || targetAmount.isEmpty ? Color.maJuTaTextSecondary.opacity(0.3) : Color.maJuTaPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.button))
                    .disabled(name.isEmpty || targetAmount.isEmpty)
                    .accessibilityLabel(L("إنشاء هدف ادخار جديد"))
                }
                .padding(MaJuTaSpacing.horizontalPadding)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle(L("هدف جديد"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("إلغاء")) { dismiss() }
                        .foregroundColor(.maJuTaTextSecondary)
                }
            }
        }
    }

    private func saveGoal() {
        let goal = SavingsGoal(
            name: name,
            nameArabic: name,
            targetAmount: targetAmount.arabicNormalizedDouble ?? 0,
            deadline: hasDeadline ? deadline : nil,
            ownerUserId: UserService.shared.currentUser?.id ?? UUID(),
            householdId: UserService.shared.currentUser?.householdId ?? UUID(),
            icon: selectedIcon,
            colorHex: selectedColor
        )
        dataStore.addSavingsGoal(goal)
        dismiss()
    }
}
