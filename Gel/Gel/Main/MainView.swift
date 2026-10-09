import SwiftUI
import GelCore

struct MainView: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    GelMark(size: 22)
                    Text("Gel").font(.system(size: 20, weight: .semibold)).tracking(-0.3).foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 10).padding(.top, 28).padding(.bottom, 18)
                ForEach([Module.home, .history, .library, .redactions]) { sidebarRow($0) }
                Spacer()
                statusFooter
                sidebarRow(.settings).padding(.bottom, 12)
            }
            .padding(.horizontal, 8)
            .navigationSplitViewColumnWidth(220)
            .background(Theme.canvas)
        } detail: {
            moduleView(state.selectedModule)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.canvas)
        }
        // No animation anywhere in the main window: any SwiftUI animation in flight during a window
        // constraint pass (e.g. a click's press feedback while the module switches) crashes AppKit (D-047).
        .transaction { $0.animation = nil; $0.disablesAnimations = true }
        .sheet(isPresented: $state.showOnboarding) { OnboardingView().tint(Theme.accent) }
        .tint(Theme.accent)
    }

    @ViewBuilder private func moduleView(_ module: Module) -> some View {
        switch module {
        case .home: HomeView()
        case .history: HistoryView()
        case .library: LibraryView()
        case .redactions: RedactionsView()
        case .settings: SettingsView()
        }
    }

    private func sidebarRow(_ module: Module) -> some View {
        let selected = state.selectedModule == module
        return Button { state.selectedModule = module } label: {
            HStack(spacing: 10) {
                Image(systemName: module.symbol)
                    .symbolVariant(selected ? .fill : .none)
                    .foregroundStyle(selected ? Theme.accent : Theme.textSecondary)
                    .frame(width: 18)
                Text(module.title).lineLimit(2)
                    .fontWeight(selected ? .medium : .regular)
                Spacer()
            }
            .font(.system(size: 13.5))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .frame(minHeight: 32)
            .background(selected ? Theme.accentSoft : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .hoverHighlight(active: !selected)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var statusColor: Color {
        switch state.localStatus {
        case .healthy: return Theme.accent
        case .cloudActive: return .orange
        case .checking: return Theme.textSecondary
        case .unavailable: return Theme.danger
        }
    }

    /// Layout never changes while indexing: progress can tick dozens of times per frame at launch, and
    /// inserting views or animating text on each tick loops AppKit's constraint pass (see D-047).
    private var statusFooter: some View {
        let p = state.indexProgress
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                StatusDot(color: statusColor, pulsing: state.localStatus == .checking)
                Text(p.map { "Reading \(min($0.done + 1, $0.total)) of \($0.total)" } ?? statusText)
                    .font(.system(size: 11).monospacedDigit()).foregroundStyle(Theme.textSecondary)
            }
            GelProgressBar(value: Double(p?.done ?? 0), total: Double(p?.total ?? 1), height: 2, animated: false)
                .padding(.leading, 20)
                .opacity(p == nil ? 0 : 1)
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

/// Status dot with a soft halo of its own colour. Static on purpose: a continuous animation in the main
/// window's hosting view loops AppKit's constraint pass during launch-time layout (D-047).
struct StatusDot: View {
    var color: Color
    var pulsing = false

    var body: some View {
        Circle().fill(color)
            .frame(width: 7, height: 7)
            .opacity(pulsing ? 0.5 : 1)
            .background(Circle().fill(color.opacity(0.25)).frame(width: 13, height: 13))
            .frame(width: 13, height: 13)
    }
}
