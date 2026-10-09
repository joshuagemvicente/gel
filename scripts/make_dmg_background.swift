// Renders the DMG installer window background (docs/deliverables/demo-download/design.md) at 1x and 2x.
// Run from the repo root:
//   swift scripts/make_dmg_background.swift <out-dir>
// Writes background.png (680x480) and background@2x.png (1360x960); combine them with
//   tiffutil -cathidpicheck background.png background@2x.png -out background.tiff
import AppKit
import CoreGraphics

let size = CGSize(width: 680, height: 480)

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

let canvas = rgb(0xF7F5F0), band = rgb(0xEFECE6), hairline = rgb(0xE7E3DA)
let textPrimary = rgb(0x1F1D1A), textSecondary = rgb(0x6F6A61), accent = rgb(0x1F7A4D)
let dropLight = rgb(0x4FC48A), dropDark = rgb(0x1F7A4D)

/// Draws `string` centred on (x, y), where y is the text's vertical centre.
func text(_ string: String, x: CGFloat, y: CGFloat, font: NSFont, color: NSColor, kern: CGFloat = 0) {
    let s = NSAttributedString(string: string, attributes: [.font: font, .foregroundColor: color, .kern: kern])
    let b = s.size()
    s.draw(at: CGPoint(x: x - b.width / 2, y: y - b.height / 2))
}

func render(scale: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size  // points, so the 2x image carries 144 dpi
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    let ctx = gc.cgContext
    // Top-left origin, matching the Finder icon positions in design.md.
    ctx.translateBy(x: 0, y: size.height)
    ctx.scaleBy(x: 1, y: -1)
    let flipped = NSGraphicsContext(cgContext: ctx, flipped: true)
    NSGraphicsContext.current = flipped

    canvas.setFill(); CGRect(origin: .zero, size: size).fill()

    // Soft lift behind the main action.
    let lift = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                          colors: [rgb(0xFFFFFF, 0.6).cgColor, rgb(0xFFFFFF, 0).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(lift, startCenter: CGPoint(x: 340, y: 186), startRadius: 0,
                           endCenter: CGPoint(x: 340, y: 186), endRadius: 300, options: [])

    // Lower band and hairline.
    band.setFill(); CGRect(x: 0, y: 290, width: size.width, height: size.height - 290).fill()
    hairline.setFill(); CGRect(x: 40, y: 290, width: 600, height: 1).fill()

    // Title and subtitle.
    text("Drag Gel to Applications", x: 340, y: 58, font: .systemFont(ofSize: 22, weight: .semibold), color: textPrimary, kern: -0.4)
    text("Then open Gel from your Applications folder.", x: 340, y: 84, font: .systemFont(ofSize: 13), color: textSecondary)

    // Caption: "TRY THE DEMO" + hint, centred as one line.
    let label = NSAttributedString(string: "TRY THE DEMO", attributes: [
        .font: NSFont.systemFont(ofSize: 10.5, weight: .semibold), .foregroundColor: accent, .kern: 0.8])
    let hint = NSAttributedString(string: "Copy Gel Sample Files to Documents first.", attributes: [
        .font: NSFont.systemFont(ofSize: 12), .foregroundColor: textSecondary])
    let gap: CGFloat = 10
    let total = label.size().width + gap + hint.size().width
    let x0 = 340 - total / 2
    label.draw(at: CGPoint(x: x0, y: 312 - label.size().height / 2))
    hint.draw(at: CGPoint(x: x0 + label.size().width + gap, y: 312 - hint.size().height / 2))

    // Arrow: a gentle dashed arc (rises 10 pt at the middle) in the Gel drop gradient, then a chevron head.
    let start = CGPoint(x: 262, y: 186), tip = CGPoint(x: 418, y: 186), control = CGPoint(x: 340, y: 166)
    let curveEnd = CGPoint(x: 401.5, y: 182.2)  // stops short of the head, on a whole dash
    let arc = CGMutablePath()
    arc.move(to: start)
    arc.addQuadCurve(to: curveEnd, control: control)
    let dashed = arc.copy(dashingWithPhase: 0, lengths: [6, 7])
        .copy(strokingWithWidth: 2.5, lineCap: .round, lineJoin: .round, miterLimit: 10)
    // Head: filled chevron aligned with the curve's end tangent.
    let angle = atan2(tip.y - control.y, tip.x - control.x) * 0.5  // halfway between the tangent and horizontal reads best
    let head = CGMutablePath()
    let len: CGFloat = 13, half: CGFloat = 6.5, notch: CGFloat = 4
    let pts = [CGPoint(x: 0, y: 0), CGPoint(x: -len, y: -half), CGPoint(x: -len + notch, y: 0), CGPoint(x: -len, y: half)]
    let t = CGAffineTransform(translationX: tip.x, y: tip.y).rotated(by: angle)
    head.addLines(between: pts.map { $0.applying(t) })
    head.closeSubpath()
    let arrow = CGMutablePath()
    arrow.addPath(dashed)
    arrow.addPath(head)
    ctx.saveGState()
    ctx.addPath(arrow)
    ctx.clip()
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                       colors: [dropLight.cgColor, dropDark.cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: start, end: tip, options: [])
    ctx.restoreGState()

    NSGraphicsContext.current = nil
    return rep
}

let out = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
for (scale, name) in [(CGFloat(1), "background.png"), (2, "background@2x.png")] {
    let data = render(scale: scale).representation(using: .png, properties: [:])!
    try data.write(to: out.appendingPathComponent(name))
    print("wrote \(name)")
}
