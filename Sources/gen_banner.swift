// Renders the GitHub social-preview / OG banner (1280×640).
// Output: docs/social-preview.png   Run: swift Sources/gen_banner.swift
import AppKit

let S: CGFloat = 1   // 1280×640 — GitHub's recommended social-preview size, < 1MB
let W: CGFloat = 1280
let H: CGFloat = 640

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(W*S), pixelsHigh: Int(H*S),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
ctx.cgContext.scaleBy(x: S, y: S)

func topY(_ yTop: CGFloat, _ h: CGFloat) -> CGFloat { H - yTop - h }
func box(_ x: CGFloat, _ yTop: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x, y: topY(yTop, h), width: w, height: h), xRadius: r, yRadius: r)
}
@discardableResult
func text(_ s: String, _ x: CGFloat, _ yTop: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular,
          color: NSColor = .white) -> CGFloat {
    let font = NSFont.systemFont(ofSize: size, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let str = NSAttributedString(string: s, attributes: attrs)
    str.draw(at: NSPoint(x: x, y: topY(yTop, str.size().height)))
    return str.size().width
}

// --- gradient background ---
let grad = NSGradient(colors: [
    NSColor(calibratedRed: 0.40, green: 0.49, blue: 0.98, alpha: 1),
    NSColor(calibratedRed: 0.60, green: 0.33, blue: 0.92, alpha: 1),
])!
grad.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -55)
// faint decorative circles
NSColor.white.withAlphaComponent(0.06).setFill()
NSBezierPath(ovalIn: NSRect(x: -120, y: H-260, width: 360, height: 360)).fill()
NSBezierPath(ovalIn: NSRect(x: W-220, y: -160, width: 380, height: 380)).fill()

// --- right: screenshot card with shadow ---
if let shot = NSImage(contentsOfFile: "docs/screenshot.png") {
    let cardH: CGFloat = 540
    let cardW = cardH * (shot.size.width / shot.size.height)
    let cx = W - cardW - 70
    let cyTop = (H - cardH) / 2
    let sh = NSShadow()
    sh.shadowColor = NSColor.black.withAlphaComponent(0.35)
    sh.shadowBlurRadius = 40
    sh.shadowOffset = NSSize(width: 0, height: -16)
    NSGraphicsContext.current?.saveGraphicsState()
    sh.set()
    let rect = NSRect(x: cx, y: topY(cyTop, cardH), width: cardW, height: cardH)
    let clip = NSBezierPath(roundedRect: rect, xRadius: 18, yRadius: 18)
    clip.addClip()
    shot.draw(in: rect)
    NSGraphicsContext.current?.restoreGraphicsState()
}

// --- left: text column ---
let lx: CGFloat = 80
// app icon
if let icon = NSImage(contentsOfFile: "docs/icon.png") {
    let r = NSRect(x: lx, y: topY(70, 110), width: 110, height: 110)
    let sh = NSShadow(); sh.shadowColor = NSColor.black.withAlphaComponent(0.3)
    sh.shadowBlurRadius = 24; sh.shadowOffset = NSSize(width: 0, height: -8)
    NSGraphicsContext.current?.saveGraphicsState(); sh.set()
    NSBezierPath(roundedRect: r, xRadius: 24, yRadius: 24).addClip()
    icon.draw(in: r)
    NSGraphicsContext.current?.restoreGraphicsState()
}
text("DropJPG", lx, 210, size: 88, weight: .heavy)
text("Drag, drop, done.", lx, 320, size: 36, weight: .semibold, color: .white)
text("Convert any image — incl. HEIC — to JPG,", lx, 374, size: 23, color: NSColor.white.withAlphaComponent(0.9))
text("right from your macOS menu bar.", lx, 406, size: 23, color: NSColor.white.withAlphaComponent(0.9))

// chips
func chip(_ label: String, _ x: CGFloat, _ yTop: CGFloat) -> CGFloat {
    let font = NSFont.systemFont(ofSize: 20, weight: .semibold)
    let w = (label as NSString).size(withAttributes: [.font: font]).width
    let padX: CGFloat = 18, h: CGFloat = 40
    NSColor.white.withAlphaComponent(0.18).setFill()
    box(x, yTop, w + padX*2, h, 20).fill()
    NSColor.white.withAlphaComponent(0.45).setStroke()
    let b = box(x, yTop, w + padX*2, h, 20); b.lineWidth = 1; b.stroke()
    text(label, x + padX, yTop + 8, size: 20, weight: .semibold)
    return x + w + padX*2 + 12
}
var cx = lx
cx = chip("HEIC → JPG", cx, 460)
cx = chip("Batch rename", cx, 460)
cx = chip("Resize", cx, 460)

// url
text("eternaxcode.github.io/dropjpg", lx, 540, size: 22, weight: .semibold,
     color: NSColor.white.withAlphaComponent(0.85))

NSGraphicsContext.restoreGraphicsState()
let data = rep.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: "docs/social-preview.png"))
print("wrote docs/social-preview.png (\(Int(W*S))x\(Int(H*S)))")
