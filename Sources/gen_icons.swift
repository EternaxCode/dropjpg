// Generates custom icons for PhotoRename — a CONVERTER, so the glyph shows
// transformation: [image tile] → [JPG].
//   Resources/menubar.png + @2x — template (black+alpha): photo tile → arrow → tile
//   Resources/appicon.png        — 1024px colored: photo → arrow → "JPG" badge
// Run:  swift Sources/gen_icons.swift
import AppKit

@discardableResult
func render(size: Int, _ draw: (NSSize) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw(NSSize(width: size, height: size))
    NSGraphicsContext.current?.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func writePNG(_ rep: NSBitmapImageRep, to path: String) {
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

/// Photo tile: rounded square + sun + mountain. `filled` = solid silhouette (menu bar),
/// otherwise a stroked frame with solid sun/mountain (app icon).
func drawPhotoTile(in r: NSRect, color: NSColor, filled: Bool) {
    color.setFill()
    color.setStroke()
    let corner = r.width * 0.18
    let frame = NSBezierPath(roundedRect: r, xRadius: corner, yRadius: corner)
    if filled {
        frame.fill()
        // punch sun + mountain as negative space by drawing nothing — keep simple solid tile
        return
    }
    frame.lineWidth = r.width * 0.10
    frame.stroke()
    // sun
    let sunR = r.width * 0.16
    let sun = NSRect(x: r.minX + r.width * 0.22, y: r.minY + r.height * 0.58,
                     width: sunR, height: sunR)
    NSBezierPath(ovalIn: sun).fill()
    // mountain
    let m = NSBezierPath()
    m.move(to: NSPoint(x: r.minX + r.width * 0.18, y: r.minY + r.height * 0.34))
    m.line(to: NSPoint(x: r.minX + r.width * 0.46, y: r.minY + r.height * 0.62))
    m.line(to: NSPoint(x: r.minX + r.width * 0.66, y: r.minY + r.height * 0.42))
    m.line(to: NSPoint(x: r.minX + r.width * 0.82, y: r.minY + r.height * 0.34))
    m.line(to: NSPoint(x: r.minX + r.width * 0.18, y: r.minY + r.height * 0.34))
    m.close()
    m.fill()
}

/// Bold right-pointing arrow centered in `r`.
func drawArrow(in r: NSRect, color: NSColor) {
    color.setFill()
    let stemH = r.height * 0.26
    let stem = NSRect(x: r.minX, y: r.midY - stemH / 2,
                      width: r.width * 0.62, height: stemH)
    NSBezierPath(roundedRect: stem, xRadius: stemH * 0.3, yRadius: stemH * 0.3).fill()
    let head = NSBezierPath()
    head.move(to: NSPoint(x: r.minX + r.width * 0.50, y: r.minY + r.height * 0.92))
    head.line(to: NSPoint(x: r.maxX, y: r.midY))
    head.line(to: NSPoint(x: r.minX + r.width * 0.50, y: r.minY + r.height * 0.08))
    head.close()
    head.fill()
}

let resDir = "Resources"
try? FileManager.default.createDirectory(atPath: resDir, withIntermediateDirectories: true)

// --- Menu bar template icon: [tile] → [tile], black on transparent ---
func drawMenubar(_ s: NSSize) {
    let h = s.height * 0.42
    let y = (s.height - h) / 2
    let tileW = s.width * 0.36
    let left = NSRect(x: s.width * 0.02, y: y, width: tileW, height: h)
    let right = NSRect(x: s.width * 0.62, y: y, width: tileW, height: h)
    let corner = tileW * 0.20
    // left: empty square (outline) = source
    NSColor.black.setStroke()
    let frame = NSBezierPath(roundedRect: left.insetBy(dx: tileW * 0.06, dy: tileW * 0.06),
                             xRadius: corner, yRadius: corner)
    frame.lineWidth = max(1.5, s.width * 0.07)
    frame.stroke()
    // right: filled square = converted output
    NSColor.black.setFill()
    NSBezierPath(roundedRect: right, xRadius: corner, yRadius: corner).fill()
    let arrow = NSRect(x: s.width * 0.37, y: s.height * 0.30,
                       width: s.width * 0.26, height: s.height * 0.40)
    drawArrow(in: arrow, color: .black)
}
writePNG(render(size: 18, drawMenubar), to: "\(resDir)/menubar.png")
writePNG(render(size: 36, drawMenubar), to: "\(resDir)/menubar@2x.png")

// --- App icon: [photo] → "JPG", colored 1024 ---
func drawAppIcon(_ s: NSSize) {
    let rect = NSRect(origin: .zero, size: s)
    let bg = NSBezierPath(roundedRect: rect.insetBy(dx: s.width * 0.04, dy: s.width * 0.04),
                          xRadius: s.width * 0.225, yRadius: s.width * 0.225)
    bg.addClip()
    NSGradient(colors: [
        NSColor(calibratedRed: 0.40, green: 0.49, blue: 0.98, alpha: 1),
        NSColor(calibratedRed: 0.60, green: 0.33, blue: 0.92, alpha: 1),
    ])!.draw(in: rect, angle: -90)

    let sh = NSShadow()
    sh.shadowColor = NSColor.black.withAlphaComponent(0.18)
    sh.shadowBlurRadius = s.width * 0.015
    sh.shadowOffset = NSSize(width: 0, height: -s.width * 0.01)
    sh.set()

    // photo tile (left)
    let tile = NSRect(x: s.width * 0.18, y: s.height * 0.36, width: s.width * 0.32, height: s.height * 0.30)
    drawPhotoTile(in: tile, color: .white, filled: false)

    // arrow (center)
    let arrow = NSRect(x: s.width * 0.50, y: s.height * 0.45, width: s.width * 0.13, height: s.height * 0.12)
    drawArrow(in: arrow, color: .white)

    // JPG badge (right)
    let badge = NSRect(x: s.width * 0.62, y: s.height * 0.40, width: s.width * 0.22, height: s.height * 0.22)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: badge, xRadius: s.width * 0.05, yRadius: s.width * 0.05).fill()
    NSShadow().set() // clear shadow for text
    let para = NSMutableParagraphStyle(); para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: s.width * 0.072, weight: .heavy),
        .foregroundColor: NSColor(calibratedRed: 0.52, green: 0.40, blue: 0.95, alpha: 1),
        .paragraphStyle: para,
    ]
    let str = "JPG" as NSString
    let tsize = str.size(withAttributes: attrs)
    str.draw(at: NSPoint(x: badge.midX - tsize.width / 2, y: badge.midY - tsize.height / 2), withAttributes: attrs)
}
writePNG(render(size: 1024, drawAppIcon), to: "\(resDir)/appicon.png")
