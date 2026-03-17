import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var dataStore = DataStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // Guest Mode Banner
            if appState.isGuestMode {
                GuestModeBanner {
                    // Tap to register — exit guest mode and go to registration
                    appState.resetAll()
                    authService.showRegistration = true
                }
            }

            TabView(selection: $appState.selectedTab) {
                DashboardView()
                    .tabItem {
                        Label(AppTab.dashboard.title, systemImage: AppTab.dashboard.icon)
                    }
                    .tag(AppTab.dashboard)

                TransactionsListView()
                    .tabItem {
                        Label(AppTab.transactions.title, systemImage: AppTab.transactions.icon)
                    }
                    .tag(AppTab.transactions)

                GoalsView()
                    .tabItem {
                        Label(AppTab.goals.title, systemImage: AppTab.goals.icon)
                    }
                    .tag(AppTab.goals)

                InvestmentsView()
                    .tabItem {
                        Label(AppTab.investments.title, systemImage: AppTab.investments.icon)
                    }
                    .tag(AppTab.investments)

                LoansView()
                    .tabItem {
                        Label(AppTab.loans.title, systemImage: AppTab.loans.icon)
                    }
                    .tag(AppTab.loans)

                if appState.isGuestMode {
                    GuestFamilyPlaceholder()
                        .tabItem {
                            Label(AppTab.family.title, systemImage: AppTab.family.icon)
                        }
                        .tag(AppTab.family)
                } else {
                    FamilyView()
                        .tabItem {
                            Label(AppTab.family.title, systemImage: AppTab.family.icon)
                        }
                        .tag(AppTab.family)
                }

                ProfileView()
                    .tabItem {
                        Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
                    }
                    .tag(AppTab.profile)
            }
            .tint(Color.maJuTaGold)
        }
        .environmentObject(dataStore)
        .sheet(isPresented: $appState.showAddTransaction) {
            AddTransactionView()
                .environmentObject(dataStore)
        }
    }
}

// MARK: - Guest Mode Banner

private struct GuestModeBanner: View {
    let onRegisterTap: () -> Void

    var body: some View {
        Button(action: onRegisterTap) {
            HStack(spacing: MaJuTaSpacing.sm) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 16))
                    .foregroundColor(.maJuTaGold)
                Text("أنت في وضع الضيف — انقر لإنشاء حساب والاحتفاظ ببياناتك")
                    .font(.maJuTaCaption)
                    .foregroundColor(.maJuTaTextPrimary)
                    .multilineTextAlignment(.trailing)
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.system(size: 11))
                    .foregroundColor(.maJuTaTextSecondary)
            }
            .padding(.horizontal, MaJuTaSpacing.horizontalPadding)
            .padding(.vertical, MaJuTaSpacing.sm)
            .background(Color.maJuTaCard)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Guest Family Placeholder

private struct GuestFamilyPlaceholder: View {
    var body: some View {
        ZStack {
            Color.maJuTaBackground.ignoresSafeArea()
            VStack(spacing: MaJuTaSpacing.md) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.maJuTaGold.opacity(0.5))
                Text("ميزة العائلة")
                    .font(.maJuTaTitle2)
                    .foregroundColor(.maJuTaTextPrimary)
                Text("تتطلب حساباً مسجلاً لمشاركة البيانات مع أفراد عائلتك")
                    .font(.maJuTaBody)
                    .foregroundColor(.maJuTaTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MaJuTaSpacing.xl)
            }
        }
        .navigationTitle(AppTab.family.title)
    }
}
