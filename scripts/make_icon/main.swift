// Renders Gel's app icon into Gel/Gel/Assets.xcassets/AppIcon.appiconset.
// Run from the repo root:
//   swiftc -O Gel/Gel/App/GelDropPath.swift scripts/make_icon/main.swift -o /tmp/make_icon && /tmp/make_icon
import AppKit
import CoreGraphics

let canvas: CGFloat = 1024

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

/// macOS-style squircle (superellipse, n = 5) inside `r`.
func squircle(_ r: CGRect, n: CGFloat = 4.6) -> CGPath {
    let path = CGMutablePath()
    let a = r.width / 2, b = r.height / 2, c = CGPoint(x: r.midX, y: r.midY)
    for i in 0...720 {
        let t = CGFloat(i) / 720 * 2 * .pi
        let ct = cos(t), st = sin(t)
        let x = c.x + a * (ct < 0 ? -1 : 1) * pow(abs(ct), 2 / n)
        let y = c.y + b * (st < 0 ? -1 : 1) * pow(abs(st), 2 / n)
        i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
    }
    path.closeSubpath()
    return path
}

func linear(_ ctx: CGContext, _ colors: [CGColor], from: CGPoint, to: CGPoint, locations: [CGFloat]? = nil) {
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: locations)!
    ctx.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

func radial(_ ctx: CGContext, _ colors: [CGColor], center: CGPoint, radius: CGFloat) {
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: nil)!
    ctx.drawRadialGradient(g, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
}

func renderMaster() -> CGImage {
    let ctx = CGContext(data: nil, width: Int(canvas), height: Int(canvas), bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Work in y-down coordinates so the drop path reads the same as in SwiftUI.
    ctx.translateBy(x: 0, y: canvas)
    ctx.scaleBy(x: 1, y: -1)

    // Body: warm squircle with the system-style drop shadow.
    let body = squircle(CGRect(x: 100, y: 100, width: 824, height: 824))
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: rgb(0x000000, 0.28))
    ctx.addPath(body); ctx.setFillColor(rgb(0xF4F0E8)); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(body); ctx.clip()
    linear(ctx, [rgb(0xFDFBF7), rgb(0xEAE3D5)], from: CGPoint(x: 512, y: 100), to: CGPoint(x: 512, y: 924))
    // Soft green bloom behind the drop, as if light passes through the gel.
    radial(ctx, [rgb(0x3FB27A, 0.20), rgb(0x3FB27A, 0)], center: CGPoint(x: 512, y: 600), radius: 380)
    // Contact shadow under the drop.
    ctx.saveGState()
    ctx.translateBy(x: 512, y: 806); ctx.scaleBy(x: 1, y: 0.16)
    radial(ctx, [rgb(0x0F3D26, 0.30), rgb(0x0F3D26, 0)], center: .zero, radius: 230)
    ctx.restoreGState()
    ctx.restoreGState()

    // Rim: a light top edge and a faint outline for definition on light Docks.
    ctx.saveGState()
    ctx.addPath(body); ctx.setLineWidth(3); ctx.setStrokeColor(rgb(0x000000, 0.06)); ctx.strokePath()
    ctx.restoreGState()

    // The drop.
    let dropRect = CGRect(x: 512 - 300, y: 206, width: 600, height: 600)
    let drop = GelDropPath.path(in: dropRect)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 36, color: rgb(0x0B3A23, 0.35))
    ctx.addPath(drop); ctx.setFillColor(rgb(0x1F7A4D)); ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(drop); ctx.clip()
    linear(ctx, [rgb(0x7AE6B0), rgb(0x2FA567), rgb(0x12543A)], from: CGPoint(x: 512, y: dropRect.minY),
           to: CGPoint(x: 512, y: dropRect.maxY), locations: [0, 0.55, 1])
    // Subsurface glow: light gathers in the round base.
    radial(ctx, [rgb(0x9BF5C8, 0.6), rgb(0x9BF5C8, 0)], center: CGPoint(x: 560, y: 700), radius: 190)
    // Edge darkening on the left gives the gel volume.
    linear(ctx, [rgb(0x0B3A23, 0.28), rgb(0x0B3A23, 0)], from: CGPoint(x: dropRect.minX + 90, y: 0), to: CGPoint(x: dropRect.minX + 230, y: 0))
    // Main specular highlight, upper left.
    ctx.saveGState()
    ctx.translateBy(x: 424, y: 480); ctx.rotate(by: -0.42); ctx.scaleBy(x: 0.55, y: 1)
    radial(ctx, [rgb(0xFFFFFF, 0.85), rgb(0xFFFFFF, 0.25), rgb(0xFFFFFF, 0)], center: .zero, radius: 120)
    ctx.restoreGState()
    // Small sharp glint.
    radial(ctx, [rgb(0xFFFFFF, 0.95), rgb(0xFFFFFF, 0)], center: CGPoint(x: 466, y: 368), radius: 28)
    ctx.restoreGState()

    // Reflected-light crescent along the lower right inside edge.
    ctx.saveGState()
    ctx.addPath(drop); ctx.clip()
    let inner = GelDropPath.path(in: dropRect.insetBy(dx: 8, dy: 8).offsetBy(dx: -10, dy: -12))
    ctx.addPath(drop); ctx.addPath(inner)
    ctx.clip(using: .evenOdd)
    linear(ctx, [rgb(0xFFFFFF, 0), rgb(0xFFFFFF, 0.38)], from: CGPoint(x: 500, y: 600), to: CGPoint(x: 700, y: 800))
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(drop); ctx.setLineWidth(3); ctx.setStrokeColor(rgb(0x0B3A23, 0.25)); ctx.strokePath()
    ctx.restoreGState()

    return ctx.makeImage()!
}

func scaled(_ image: CGImage, to px: Int) -> Data {
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: px, height: px))
    return NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
}

let out = URL(fileURLWithPath: "Gel/Gel/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
let master = renderMaster()
var images: [String] = []
for pt in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(pt)x\(pt)\(scale == 2 ? "@2x" : "").png"
        try scaled(master, to: pt * scale).write(to: out.appendingPathComponent(name))
        images.append(#"{ "idiom" : "mac", "scale" : "\#(scale)x", "size" : "\#(pt)x\#(pt)", "filename" : "\#(name)" }"#)
    }
}
let contents = "{\n  \"images\" : [\n    \(images.joined(separator: ",\n    "))\n  ],\n  \"info\" : { \"author\" : \"xcode\", \"version\" : 1 }\n}\n"
try contents.write(to: out.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
try #"{ "info" : { "author" : "xcode", "version" : 1 } }"#.write(to: out.deletingLastPathComponent().appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Wrote \(images.count) icon sizes to \(out.path)")
