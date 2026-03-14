import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showAddGoal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MaJuTaSpacing.md) {
                    // Summary Card
                    goalsSummaryCard

                    // Goals List
                    if dataStore.savingsGoals.isEmpty {
                        emptyGoalsState
                    } else {
                        VStack(spacing: MaJuTaSpacing.md) {
                            ForEach(dataStore.savingsGoals) { goal in
                                NavigationLink(destination: GoalDetailView(goal: goal)) {
                                    GoalCardView(goal: goal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Emergency Fund Card
                    NavigationLink(destination: EmergencyFundView()) {
                        EmergencyFundCardView(
                            months: dataStore.emergencyMonths,
                            balance: dataStore.emergencyFundBalance
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
                .padding(.vertical, MaJuTaSpacing.md)
                .padding(.bottom, MaJuTaSpacing.xxxl)
            }
            .background(Color.maJuTaBackground)
            .navigationTitle("الأهداف")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showAddGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.maJuTaGold)
                    }
                }
            }
            .sheet(isPresented: $showAddGoal) {
                AddGoalView()
                    .environmentObject(dataStore)
            }
        }
    }

    private var goalsSummaryCard: some View {
        let totalTarget = dataStore.savingsGoals.reduce(0) { $0 + $1.targetAmount }
        let totalSaved  = dataStore.savingsGoals.reduce(0) { $0 + $1.currentAmount }
        let progress    = totalTarget > 0 ? totalSaved / totalTarget : 0

        return HStack(spacing: MaJuTaSpacing.lg) {
            // Overall progress ring
            ZStack {
                Circle()
                    .stroke(Color.maJuTaBackground, lineWidth: 10)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(LinearGradient.goldGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(.maJuTaBodyBold)
                    .foregroundColor(.maJuTaTextPrimary)
            }

            VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
                Text("إجمالي الأهداف")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextSecondary)
                SARText.mediumNumber(totalSaved)
                HStack(spacing: 2) {
                    Text("من").font(.maJuTaCaption).foregroundColor(.maJuTaTextSecondary)
                    SARText.caption(totalTarget, color: .maJuTaTextSecondary)
                }
            }

            Spacer()
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }

    private var emptyGoalsState: some View {
        VStack(spacing: MaJuTaSpacing.md) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundColor(.maJuTaTextSecondary.opacity(0.4))
            Text("لا توجد أهداف ادخار")
                .font(.maJuTaSectionTitle)
                .foregroundColor(.maJuTaTextSecondary)
            Text("أنشئ هدفك الأول لتبدأ رحلة الادخار")
                .font(.maJuTaCaption)
                .foregroundColor(.maJuTaTextSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MaJuTaSpacing.xxl)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
    }
}

// MARK: - Goal Card Component
struct GoalCardView: View {
    let goal: SavingsGoal

    var body: some View {
        VStack(alignment: .trailing, spacing: MaJuTaSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if goal.isCompleted {
                        Label("مكتمل", systemImage: "checkmark.circle.fill")
                            .font(.maJuTaLabel)
                            .foregroundColor(.maJuTaPositive)
                    } else if let deadline = goal.deadline {
                        Text(deadline.gregorianFormatted)
                            .font(.maJuTaCaption)
                            .foregroundColor(.maJuTaTextSecondary)
                    }
                }

                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: goal.colorHex).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: goal.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: goal.colorHex))
                }

                Text(goal.nameArabic.isEmpty ? goal.name : goal.nameArabic)
                    .font(.maJuTaBodyBold)
                    .foregroundColor(.maJuTaTextPrimary)
            }

            // Progress Bar
            VStack(alignment: .trailing, spacing: 6) {
                HStack {
                    SARText.caption(goal.targetAmount, color: .maJuTaTextSecondary)
                    Spacer()
                    SARText.bodyBold(goal.currentAmount)
                }

                GeometryReader { geo in
                    ZStack(alignment: .trailing) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.maJuTaBackground)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                colors: [Color(hex: goal.colorHex), Color(hex: goal.colorHex).opacity(0.7)],
                                startPoint: .trailing,
                                endPoint: .leading
                            ))
                            .frame(width: geo.size.width * goal.progress, height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(goal.progressPercentage)% مكتمل")
                    .font(.maJuTaLabel)
                    .foregroundColor(Color(hex: goal.colorHex))
            }
        }
        .padding(MaJuTaSpacing.lg)
        .background(Color.maJuTaCard)
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }
}

// MARK: - Emergency Fund Card
struct EmergencyFundCardView: View {
    let months: Double
    let balance: Double

    var body: some View {
        HStack(spacing: MaJuTaSpacing.md) {
            VStack(alignment: .trailing, spacing: MaJuTaSpacing.sm) {
                Text("صندوق الطوارئ")
                    .font(.maJuTaBodyBold)
                    .foregroundColor(.white)
                SARText.mediumNumber(balance, color: .white)
                Text("يكفي \(String(format: "%.1f", months)) أشهر")
                    .font(.maJuTaCaption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 6)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: min(months / 6, 1))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .padding(MaJuTaSpacing.lg)
        .background(
            LinearGradient(
                colors: [Color(hex: "#EF4444"), Color(hex: "#DC2626")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: MaJuTaRadius.card))
        .maJuTaCardShadow()
    }
}
