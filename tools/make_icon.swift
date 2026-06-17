import AppKit

// Renders the SpeakRate app icon at a given size into a PNG.
// Concept: rounded-rect gradient tile + white speaker + sound waves + fast-forward chevrons.

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else { image.unlockFocus(); return image }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // Background rounded rect with gradient (macOS Big Sur style squircle-ish)
    let corner = size * 0.2237
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: size*0.06, dy: size*0.06),
                              xRadius: corner, yRadius: corner)
    bgPath.addClip()

    let colors = [
        NSColor(calibratedRed: 0.20, green: 0.72, blue: 0.74, alpha: 1).cgColor, // teal
        NSColor(calibratedRed: 0.16, green: 0.45, blue: 0.86, alpha: 1).cgColor  // blue
    ] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: rect.minX, y: rect.maxY),
                           end: CGPoint(x: rect.maxX, y: rect.minY),
                           options: [])

    // Speaker + waves, drawn in white, centered-left
    ctx.setFillColor(NSColor.white.cgColor)
    ctx.setStrokeColor(NSColor.white.cgColor)

    let cx = size * 0.40
    let cy = size * 0.50
    let unit = size * 0.5

    // Speaker body (rectangle + trapezoid cone)
    let boxW = unit * 0.16
    let boxH = unit * 0.34
    let boxX = cx - unit * 0.30
    let speakerBox = CGRect(x: boxX, y: cy - boxH/2, width: boxW, height: boxH)
    ctx.fill(speakerBox)

    let cone = CGMutablePath()
    cone.move(to: CGPoint(x: boxX + boxW, y: cy - boxH/2))
    cone.addLine(to: CGPoint(x: boxX + boxW + unit*0.22, y: cy - boxH*0.95))
    cone.addLine(to: CGPoint(x: boxX + boxW + unit*0.22, y: cy + boxH*0.95))
    cone.addLine(to: CGPoint(x: boxX + boxW, y: cy + boxH/2))
    cone.closeSubpath()
    ctx.addPath(cone)
    ctx.fillPath()

    // Sound waves (two arcs) — using fast-forward chevrons to imply speed
    ctx.setLineWidth(unit * 0.07)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    let chevronX = cx + unit * 0.12
    for (i, scale) in [0.0, 0.18, 0.36].enumerated() {
        let x = chevronX + CGFloat(scale) * unit
        let h = unit * 0.22 * (1.0 - CGFloat(i) * 0.05)
        let ch = CGMutablePath()
        ch.move(to: CGPoint(x: x, y: cy + h))
        ch.addLine(to: CGPoint(x: x + unit*0.13, y: cy))
        ch.addLine(to: CGPoint(x: x, y: cy - h))
        ctx.addPath(ch)
        ctx.strokePath()
    }

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to path: String, pixelSize: Int) {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixelSize, pixelsHigh: pixelSize,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                              colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: pixelSize, height: pixelSize)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    drawIcon(size: CGFloat(pixelSize)).draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let sizes = [16, 32, 64, 128, 256, 512, 1024]
for s in sizes {
    writePNG(NSImage(), to: "\(outDir)/icon_\(s).png", pixelSize: s)
}
print("done")
