import SwiftUI
import AppKit

/// The Gel drop as a SwiftUI shape (same path as the app icon and menu bar mark).
struct GelDrop: Shape {
    func path(in rect: CGRect) -> Path { Path(GelDropPath.path(in: rect)) }
}

/// The brand mark: a glossy gel drop. `thinking` breathes while Gel works; `listening` swells with the mic level.
struct GelMark: View {
    enum Mode: Equatable { case still, thinking, listening(Float) }

    var size: CGFloat
    var mode: Mode = .still
    @State private var up = false

    private static let top = Theme.dynamic(light: NSColor(hex: 0x5BD195), dark: NSColor(hex: 0x6ADDA3))
    private static let bottom = Theme.dynamic(light: NSColor(hex: 0x1A6B43), dark: NSColor(hex: 0x24885A))

    var body: some View {
        switch mode {
        case .thinking:
            drop
                .scaleEffect(x: up ? 1.03 : 1, y: up ? 0.96 : 1, anchor: .bottom)
                .scaleEffect(Motion.reduce ? 1 : (up ? 1.06 : 0.98))
                .opacity(Motion.reduce ? (up ? 0.6 : 1) : 1)
                .onAppear { withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { up = true } }
                .onDisappear { up = false }
        case .listening(let level):
            drop.scaleEffect(Motion.reduce ? 1 : 1 + CGFloat(max(0, min(1, level * 2))) * 0.18, anchor: .bottom)
                .animation(Motion.snappy, value: level)
        case .still:
            drop
        }
    }

    private var drop: some View {
        ZStack {
            GelDrop().fill(LinearGradient(colors: [Self.top, Self.bottom], startPoint: .top, endPoint: .bottom))
            // Light gathering in the round base.
            Circle().fill(RadialGradient(colors: [.white.opacity(0.35), .clear], center: .center, startRadius: 0, endRadius: size * 0.25))
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(x: size * 0.06, y: size * 0.2)
            // Specular highlight, upper left.
            Ellipse().fill(.white.opacity(0.7))
                .frame(width: size * 0.12, height: size * 0.22)
                .rotationEffect(.degrees(24))
                .blur(radius: size * 0.025)
                .offset(x: -size * 0.13, y: size * 0.02)
            GelDrop().stroke(Color.black.opacity(0.12), lineWidth: max(0.5, size * 0.012))
        }
        .clipShape(GelDrop())
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

enum BrandImage {
    /// Menu bar template: the drop outline with a small highlight stroke, 18 × 18 pt.
    static let menuBar: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let drop = GelDropPath.path(in: rect.insetBy(dx: 1.5, dy: 1.2))
            ctx.addPath(drop)
            ctx.setLineWidth(1.5)
            ctx.setLineJoin(.round)
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.strokePath()
            // Highlight arc inside the left side of the drop.
            ctx.setLineCap(.round)
            ctx.setLineWidth(1.3)
            ctx.addArc(center: CGPoint(x: 9, y: 11.3), radius: 3.6, startAngle: .pi * 0.95, endAngle: .pi * 0.6, clockwise: true)
            ctx.strokePath()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Gel"
        return image
    }()
}
