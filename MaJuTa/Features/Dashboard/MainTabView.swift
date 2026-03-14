import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var dataStore = DataStore.shared

    var body: some View {
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

            FamilyView()
                .tabItem {
                    Label(AppTab.family.title, systemImage: AppTab.family.icon)
                }
                .tag(AppTab.family)

            ProfileView()
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
                }
                .tag(AppTab.profile)
        }
        .tint(Color.maJuTaGold)
        .environmentObject(dataStore)
        .sheet(isPresented: $appState.showAddTransaction) {
            AddTransactionView()
                .environmentObject(dataStore)
        }
    }
}
