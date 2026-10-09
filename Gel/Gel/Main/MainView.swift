import SwiftUI
import GelCore

struct MainView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill").foregroundStyle(Theme.accent)
                    Text("Gel").font(.system(size: 20, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 12).padding(.top, 28).padding(.bottom, 16)
                ForEach([Module.home, .history, .library, .redactions]) { sidebarRow($0) }
                Spacer()
                statusFooter
                sidebarRow(.settings).padding(.bottom, 12)
            }
            .padding(.horizontal, 8)
            .navigationSplitViewColumnWidth(220)
            .background(Theme.canvas)
        } detail: {
            Group {
                switch state.selectedModule {
                case .home: HomeView()
                case .history: HistoryView()
                case .library: LibraryView()
                case .redactions: RedactionsView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.canvas)
        }
        .sheet(isPresented: $state.showOnboarding) { OnboardingView() }
    }

    private func sidebarRow(_ module: Module) -> some View {
        Button { state.selectedModule = module } label: {
            HStack(spacing: 10) {
                Image(systemName: module.symbol).frame(width: 18)
                Text(module.title).lineLimit(2)
                Spacer()
            }
            .font(.system(size: 13.5))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(state.selectedModule == module ? Theme.accentSoft : .clear, in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var statusFooter: some View {
        HStack(spacing: 6) {
            Circle().fill(state.localStatus == .healthy ? Theme.accent : (state.localStatus == .cloudActive ? Color.orange : Theme.danger))
                .frame(width: 7, height: 7)
            Text(statusText).font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 12).padding(.bottom, 8)
    }

    private var statusText: String {
        switch state.localStatus {
        case .checking: return "Checking…"
        case .healthy: return "Running on this Mac"
        case .cloudActive: return "Cloud fallback active"
        case .unavailable: return "Local model unavailable"
        }
    }
}
