import SwiftUI
import GelCore

/// Shared look and feel (docs/features/app-shell/design.md): warm minimal, one deep-green accent.
enum Theme {
    static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light })
    }

    static let canvas = dynamic(light: NSColor(hex: 0xF7F5F0), dark: NSColor(hex: 0x1E1D1B))
    static let card = dynamic(light: .white, dark: NSColor(hex: 0x282624))
    static let hairline = dynamic(light: NSColor(hex: 0xE7E3DA), dark: NSColor(hex: 0x3A3733))
    static let textPrimary = dynamic(light: NSColor(hex: 0x1F1D1A), dark: NSColor(hex: 0xF2EFE9))
    static let textSecondary = dynamic(light: NSColor(hex: 0x6F6A61), dark: NSColor(hex: 0xA8A296))
    static let accent = dynamic(light: NSColor(hex: 0x1F7A4D), dark: NSColor(hex: 0x3FB27A))
    static let accentSoft = dynamic(light: NSColor(hex: 0x1F7A4D, alpha: 0.12), dark: NSColor(hex: 0x3FB27A, alpha: 0.18))
    static let danger = dynamic(light: NSColor(hex: 0xB3402E), dark: NSColor(hex: 0xE0705C))
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}

struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.hairline))
    }
}

struct ProviderBadge: View {
    var provider: ProviderKind
    var model: String

    private var shortModel: String {
        if model.hasPrefix("qwen3:4b") { return "Qwen3 4B" }
        return model.count > 22 ? String(model.prefix(22)) + "…" : model
    }

    var body: some View {
        Text("\(provider == .local ? "Local" : "Cloud") · \(shortModel)")
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .foregroundStyle(provider == .local ? Theme.accent : Theme.textSecondary)
            .background(provider == .local ? Theme.accentSoft : Theme.hairline.opacity(0.6), in: Capsule())
            .accessibilityLabel(provider == .local ? "Answered on this Mac" : "Answered by cloud fallback")
    }
}

struct CitationChip: View {
    var citation: Citation
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(citation.label)
                .font(.system(size: 11.5))
                .lineLimit(1)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .foregroundStyle(Theme.textPrimary)
                .background(Theme.canvas, in: Capsule())
                .overlay(Capsule().strokeBorder(Theme.hairline))
        }
        .buttonStyle(.plain)
        .help(citation.snippet)
    }
}

struct StatCard: View {
    var value: String
    var label: String

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                Text(value).font(.system(size: 34, design: .serif)).foregroundStyle(Theme.textPrimary)
                Text(label).font(.system(size: 12)).foregroundStyle(Theme.textSecondary).lineLimit(2)
            }
        }
    }
}

struct LockedLabel: View {
    var organization: String
    var body: some View {
        Label("Managed by \(organization)", systemImage: "lock.fill")
            .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
    }
}

struct EmptyStateView: View {
    var symbol: String
    var title: String
    var hint: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol).font(.system(size: 28)).foregroundStyle(Theme.textSecondary)
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            Text(hint).font(.system(size: 12)).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

/// Wrapping flow layout for citation chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > width, x > 0 { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowHeight + spacing; rowHeight = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing
            rowHeight = max(rowHeight, s.height)
        }
    }
}

struct ModuleHeader: View {
    var title: String
    var body: some View {
        Text(title).font(.system(size: 26, weight: .semibold)).foregroundStyle(Theme.textPrimary)
    }
}
