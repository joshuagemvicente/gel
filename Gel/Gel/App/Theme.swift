import SwiftUI
import GelCore

/// Shared look and feel (docs/features/app-shell/design.md): warm minimal, one deep-green accent.
enum Theme {
    static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: dynamicNS(light: light, dark: dark))
    }

    static func dynamicNS(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light }
    }

    static let canvas = dynamic(light: NSColor(hex: 0xF7F5F0), dark: NSColor(hex: 0x1E1D1B))
    static let card = dynamic(light: .white, dark: NSColor(hex: 0x282624))
    static let hairline = dynamic(light: NSColor(hex: 0xE7E3DA), dark: NSColor(hex: 0x3A3733))
    static let textPrimary = dynamic(light: NSColor(hex: 0x1F1D1A), dark: NSColor(hex: 0xF2EFE9))
    static let textSecondary = dynamic(light: NSColor(hex: 0x6F6A61), dark: NSColor(hex: 0xA8A296))
    static let accent = dynamic(light: NSColor(hex: 0x1F7A4D), dark: NSColor(hex: 0x3FB27A))
    static let accentSoft = dynamic(light: NSColor(hex: 0x1F7A4D, alpha: 0.12), dark: NSColor(hex: 0x3FB27A, alpha: 0.18))
    /// Fill behind white text: stays ≥ 4.5:1 in both appearances.
    static let accentFill = dynamic(light: NSColor(hex: 0x1F7A4D), dark: NSColor(hex: 0x217F51))
    static let danger = dynamic(light: NSColor(hex: 0xB3402E), dark: NSColor(hex: 0xE0705C))
    static let dangerSoft = dynamic(light: NSColor(hex: 0xB3402E, alpha: 0.12), dark: NSColor(hex: 0xE0705C, alpha: 0.18))
    static let hover = dynamic(light: NSColor(hex: 0x1F1D1A, alpha: 0.05), dark: NSColor(hex: 0xF2EFE9, alpha: 0.06))
    static let shadow = dynamic(light: NSColor(hex: 0x3A2F1E, alpha: 0.10), dark: NSColor(hex: 0x000000, alpha: 0.35))
    static let viewerBackground = dynamicNS(light: NSColor(hex: 0xEFECE6), dark: NSColor(hex: 0x1E1D1B))
}

/// Motion tokens (docs/features/polish/design.md). Critically damped by default; `pop` only for arrivals.
/// With Reduce Motion on, every token is a short cross-fade and transitions drop their movement.
enum Motion {
    static var reduce: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    static let fade = Animation.easeOut(duration: 0.15)
    static var snappy: Animation { reduce ? fade : .spring(response: 0.28, dampingFraction: 1) }
    static var smooth: Animation { reduce ? fade : .spring(response: 0.42, dampingFraction: 1) }
    static var pop: Animation { reduce ? fade : .spring(response: 0.35, dampingFraction: 0.72) }
    static func stagger(_ index: Int) -> Double { reduce ? 0 : Double(min(index, 8)) * 0.035 }
}

extension AnyTransition {
    /// Fade in while rising `y` points; fade out in place.
    static func rise(_ y: CGFloat = 8) -> AnyTransition {
        Motion.reduce ? .opacity : .asymmetric(insertion: .opacity.combined(with: .offset(y: y)), removal: .opacity)
    }

    /// Directional push used by onboarding steps.
    static func push(forward: Bool) -> AnyTransition {
        guard !Motion.reduce else { return .opacity }
        return .asymmetric(insertion: .opacity.combined(with: .offset(x: forward ? 24 : -24)),
                           removal: .opacity.combined(with: .offset(x: forward ? -24 : 24)))
    }

    static var popIn: AnyTransition { Motion.reduce ? .opacity : .opacity.combined(with: .scale(scale: 0.9)) }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}

// MARK: - Interaction feedback

/// Press scale for plain buttons: feedback on mouse-down, not on release.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !Motion.reduce ? scale : 1)
            .animation(Motion.snappy, value: configuration.isPressed)
    }
}

struct HoverHighlight: ViewModifier {
    var radius: CGFloat = 8
    var active = true
    @State private var hovering = false

    func body(content: Content) -> some View {
        content
            .background(hovering && active ? Theme.hover : .clear, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .onHover { h in withAnimation(Motion.snappy) { hovering = h } }
    }
}

extension View {
    func hoverHighlight(radius: CGFloat = 8, active: Bool = true) -> some View {
        modifier(HoverHighlight(radius: radius, active: active))
    }

    /// One horizontal shake when `trigger` changes (errors). Nothing under Reduce Motion.
    func shake(_ trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
            .animation(Motion.reduce ? nil : .linear(duration: 0.35), value: trigger)
    }
}

/// Arrives with `pop` after `Motion.stagger(index)`; keeps its layout space while hidden so lists don't jump.
struct StaggeredAppear: ViewModifier {
    var index: Int
    var rise: CGFloat = 0
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible || Motion.reduce ? 1 : 0.9)
            .offset(y: visible || Motion.reduce ? 0 : rise)
            .onAppear { withAnimation((rise > 0 ? Motion.smooth : Motion.pop).delay(Motion.stagger(index))) { visible = true } }
    }
}

extension View {
    func staggeredAppear(_ index: Int, rise: CGFloat = 0) -> some View {
        modifier(StaggeredAppear(index: index, rise: rise))
    }
}

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 6 * sin(animatableData * .pi * 6), y: 0))
    }
}

/// Brand buttons. The accent fill stays when the window isn't key (unlike `.borderedProminent`).
struct GelButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary }
    var kind: Kind = .primary
    var large = false

    func makeBody(configuration: Configuration) -> some View {
        GelButtonBody(configuration: configuration, kind: kind, large: large)
    }

    private struct GelButtonBody: View {
        let configuration: ButtonStyleConfiguration
        let kind: Kind
        let large: Bool
        @Environment(\.isEnabled) private var enabled
        @State private var hovering = false

        var body: some View {
            configuration.label
                .font(.system(size: large ? 14 : 13, weight: .medium))
                .lineLimit(1)
                .padding(.horizontal, large ? 18 : 14)
                .frame(minHeight: large ? 34 : 28)
                .foregroundStyle(kind == .primary ? Color.white : Theme.textPrimary)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(kind == .primary ? Theme.accentFill : Theme.card)
                        .shadow(color: kind == .primary && enabled ? Theme.accent.opacity(0.25) : .clear, radius: 4, y: 1)
                }
                .overlay {
                    if kind == .secondary {
                        RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Theme.hairline)
                    }
                }
                .brightness(hovering && enabled ? (kind == .primary ? 0.06 : -0.02) : 0)
                .scaleEffect(configuration.isPressed && enabled && !Motion.reduce ? 0.97 : 1)
                .opacity(enabled ? 1 : 0.4)
                .contentShape(Rectangle())
                .onHover { h in withAnimation(Motion.snappy) { hovering = h } }
                .animation(Motion.snappy, value: configuration.isPressed)
        }
    }
}

extension ButtonStyle where Self == GelButtonStyle {
    static var gelPrimary: GelButtonStyle { GelButtonStyle(kind: .primary) }
    static var gelSecondary: GelButtonStyle { GelButtonStyle(kind: .secondary) }
}

// MARK: - Components

struct Card<Content: View>: View {
    var padding: CGFloat = 16
    /// Stretch to the height offered (equal-height cards in a row).
    var fillHeight = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: fillHeight ? .infinity : nil, alignment: .topLeading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.hairline))
    }
}

/// A symbol in a soft rounded square; the visual anchor for stats, rows and settings sections.
struct IconChip: View {
    var symbol: String
    var tint: Color = Theme.accent
    var background: Color = Theme.accentSoft
    var size: CGFloat = 26

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(background, in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
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
        HStack(spacing: 4) {
            Image(systemName: provider == .local ? "cpu" : "cloud").font(.system(size: 9.5, weight: .semibold))
            Text(model.isEmpty ? (provider == .local ? "Local" : "Cloud") : "\(provider == .local ? "Local" : "Cloud") · \(shortModel)")
        }
        .font(.system(size: 11, weight: .medium))
        .padding(.horizontal, 8).padding(.vertical, 3)
        .foregroundStyle(provider == .local ? Theme.accent : Theme.textSecondary)
        .background(provider == .local ? Theme.accentSoft : Theme.hairline.opacity(0.6), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(provider == .local ? "Answered on this Mac" : "Answered by cloud fallback")
    }
}

struct CitationChip: View {
    var citation: Citation
    var action: () -> Void
    @State private var hovering = false

    private var fileLabel: String {
        "\((citation.fileName as NSString).deletingPathExtension) p.\(citation.page + 1)"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("\(citation.id)")
                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                    .foregroundStyle(hovering ? Color.white : Theme.accent)
                    .frame(width: 16, height: 16)
                    .background(hovering ? Theme.accentFill : Theme.accentSoft, in: Circle())
                Text(fileLabel).font(.system(size: 11.5)).lineLimit(1)
            }
            .padding(.leading, 4).padding(.trailing, 10).padding(.vertical, 3)
            .foregroundStyle(Theme.textPrimary)
            .background(hovering ? Theme.accentSoft : Theme.canvas, in: Capsule())
            .overlay(Capsule().strokeBorder(hovering ? Theme.accent.opacity(0.6) : Theme.hairline))
            .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle(scale: 0.95))
        .onHover { h in withAnimation(Motion.snappy) { hovering = h } }
        .help(citation.snippet)
        .accessibilityLabel("Source \(citation.id): \(fileLabel)")
    }
}

struct StatCard: View {
    var value: String
    var label: String
    var symbol: String? = nil
    var numeric: Double? = nil

    var body: some View {
        Card(fillHeight: true) {
            VStack(alignment: .leading, spacing: 10) {
                if let symbol { IconChip(symbol: symbol) }
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 34, design: .serif))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(value: numeric ?? 0))
                    Text(label).font(.system(size: 12)).foregroundStyle(Theme.textSecondary).lineLimit(2)
                }
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
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Theme.accent)
                .frame(width: 56, height: 56)
                .background(Theme.accentSoft, in: Circle())
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            Text(hint).font(.system(size: 12)).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
                .frame(maxWidth: 280)
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
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 26, weight: .semibold)).tracking(-0.4).foregroundStyle(Theme.textPrimary)
            if let subtitle {
                Text(subtitle).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                    .contentTransition(.opacity)
            }
        }
    }
}

/// Section label used above lists ("TODAY", "REDACTED FILES").
struct SectionLabel: View {
    var text: String
    var body: some View {
        Text(text.uppercased()).font(.system(size: 11, weight: .semibold)).tracking(0.6).foregroundStyle(Theme.textSecondary)
    }
}

/// Thin rounded progress bar in the accent colour; animates its fill.
struct GelProgressBar: View {
    var value: Double
    var total: Double
    var height: CGFloat = 4
    /// Off for values that can change many times per frame (indexing).
    var animated = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule().fill(Theme.accent)
                    .frame(width: max(height, geo.size.width * CGFloat(min(1, value / max(total, 1)))))
            }
        }
        .frame(height: height)
        .animation(animated ? Motion.smooth : nil, value: value)
        .accessibilityElement()
        .accessibilityValue("\(Int(value)) of \(Int(total))")
    }
}
