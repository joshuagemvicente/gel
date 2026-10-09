import CoreGraphics

/// The Gel mark: a teardrop with a pointed top and a round base, in a y-down unit square.
/// CoreGraphics only, so `scripts/make_icon` can compile it alongside the icon renderer.
enum GelDropPath {
    static func path(in r: CGRect) -> CGPath {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
        let path = CGMutablePath()
        path.move(to: p(0.5, 0.02))
        path.addCurve(to: p(0.84, 0.63), control1: p(0.57, 0.15), control2: p(0.84, 0.38))
        path.addCurve(to: p(0.5, 0.98), control1: p(0.84, 0.83), control2: p(0.69, 0.98))
        path.addCurve(to: p(0.16, 0.63), control1: p(0.31, 0.98), control2: p(0.16, 0.83))
        path.addCurve(to: p(0.5, 0.02), control1: p(0.16, 0.38), control2: p(0.43, 0.15))
        path.closeSubpath()
        return path
    }
}
