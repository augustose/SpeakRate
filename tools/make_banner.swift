import AppKit

// Generates a hero banner for the README: gradient bg + app icon glyph + title + tagline.

let W = 1280, H = 500
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H,
                          bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                          colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

let rect = CGRect(x: 0, y: 0, width: W, height: H)

// Background gradient (teal -> blue, matching the icon)
let colors = [
    NSColor(calibratedRed: 0.12, green: 0.55, blue: 0.62, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.10, green: 0.30, blue: 0.62, alpha: 1).cgColor
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: H), end: CGPoint(x: W, y: 0), options: [])

// Soft decorative circles
ctx.setFillColor(NSColor.white.withAlphaComponent(0.05).cgColor)
ctx.fillEllipse(in: CGRect(x: W-360, y: H-380, width: 520, height: 520))
ctx.fillEllipse(in: CGRect(x: -120, y: -180, width: 360, height: 360))

// --- Speaker + chevrons glyph (left side) ---
let gx: CGFloat = 200, gy: CGFloat = CGFloat(H)/2, u: CGFloat = 150
ctx.setFillColor(NSColor.white.cgColor)
ctx.setStrokeColor(NSColor.white.cgColor)
let boxW = u*0.16, boxH = u*0.34, boxX = gx - u*0.30
ctx.fill(CGRect(x: boxX, y: gy - boxH/2, width: boxW, height: boxH))
let cone = CGMutablePath()
cone.move(to: CGPoint(x: boxX + boxW, y: gy - boxH/2))
cone.addLine(to: CGPoint(x: boxX + boxW + u*0.22, y: gy - boxH*0.95))
cone.addLine(to: CGPoint(x: boxX + boxW + u*0.22, y: gy + boxH*0.95))
cone.addLine(to: CGPoint(x: boxX + boxW, y: gy + boxH/2))
cone.closeSubpath()
ctx.addPath(cone); ctx.fillPath()
ctx.setLineWidth(u*0.07); ctx.setLineCap(.round); ctx.setLineJoin(.round)
let chevronX = gx + u*0.12
for (i, scale) in [0.0, 0.18, 0.36].enumerated() {
    let x = chevronX + CGFloat(scale)*u
    let h = u*0.22 * (1.0 - CGFloat(i)*0.05)
    let ch = CGMutablePath()
    ch.move(to: CGPoint(x: x, y: gy + h))
    ch.addLine(to: CGPoint(x: x + u*0.13, y: gy))
    ch.addLine(to: CGPoint(x: x, y: gy - h))
    ctx.addPath(ch); ctx.strokePath()
}

// --- Text (right side) ---
func draw(_ s: String, x: CGFloat, y: CGFloat, size: CGFloat, weight: NSFont.Weight, alpha: CGFloat = 1) {
    let p = NSMutableParagraphStyle()
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: NSColor.white.withAlphaComponent(alpha),
        .paragraphStyle: p
    ]
    NSString(string: s).draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
}

let tx: CGFloat = 410
draw("SpeakRate", x: tx, y: CGFloat(H)/2 + 30, size: 92, weight: .bold)
draw("Read selected text aloud — at any speed.", x: tx+4, y: CGFloat(H)/2 - 35, size: 32, weight: .regular, alpha: 0.9)

// Shortcut chips
func chip(_ s: String, x: CGFloat, y: CGFloat) -> CGFloat {
    let font = NSFont.monospacedSystemFont(ofSize: 22, weight: .semibold)
    let textW = (s as NSString).size(withAttributes: [.font: font]).width
    let padX: CGFloat = 18, w = textW + padX*2, h: CGFloat = 44
    let path = NSBezierPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), xRadius: 10, yRadius: 10)
    NSColor.white.withAlphaComponent(0.18).setFill(); path.fill()
    NSString(string: s).draw(at: NSPoint(x: x+padX, y: y+9),
        withAttributes: [.font: font, .foregroundColor: NSColor.white])
    return x + w + 14
}
var cx = tx + 4
cx = chip("⌥⌘R  Read", x: cx, y: CGFloat(H)/2 - 110)
cx = chip("⌥⌘→  Faster", x: cx, y: CGFloat(H)/2 - 110)
cx = chip("⌥⌘←  Slower", x: cx, y: CGFloat(H)/2 - 110)

NSGraphicsContext.restoreGraphicsState()
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let data = rep.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: "\(outDir)/banner.png"))
print("banner written")
