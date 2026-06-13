// Renders a faithful mockup of the DropJPG window for README/docs.
// Output: docs/screenshot.png   Run: swift Sources/gen_hero.swift
// No global flip: shapes are orientation-agnostic, text draws upright in a
// non-flipped context. Layout is authored top-down; topY() converts to bottom-left.
import AppKit

let S: CGFloat = 2            // retina scale
let W: CGFloat = 440          // logical window width
let TITLE: CGFloat = 30       // title bar height
let CH: CGFloat = 500         // content height
let H = TITLE + CH            // total logical height

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(W * S), pixelsHigh: Int(H * S),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = ctx
ctx.cgContext.scaleBy(x: S, y: S)

// y given as distance from TOP; convert to bottom-left origin for AppKit.
func topY(_ yTop: CGFloat, _ h: CGFloat) -> CGFloat { H - yTop - h }
func box(_ x: CGFloat, _ yTop: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: NSRect(x: x, y: topY(yTop, h), width: w, height: h), xRadius: r, yRadius: r)
}
let GRAY = NSColor(calibratedWhite: 0.55, alpha: 1)
let DARK = NSColor(calibratedWhite: 0.15, alpha: 1)
func text(_ s: String, _ x: CGFloat, _ yTop: CGFloat, size: CGFloat, weight: NSFont.Weight = .regular,
          color: NSColor = DARK, mono: Bool = false) {
    let font = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: weight)
                    : NSFont.systemFont(ofSize: size, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let str = NSAttributedString(string: s, attributes: attrs)
    str.draw(at: NSPoint(x: x, y: topY(yTop, str.size().height)))
}

// --- window background ---
NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
box(0, 0, W, H, 12).fill()

// --- title bar ---
NSColor(calibratedWhite: 0.90, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: H - TITLE, width: W, height: TITLE)).fill()
for (i, c) in [NSColor(red: 1, green: 0.37, blue: 0.35, alpha: 1),
               NSColor(red: 1, green: 0.74, blue: 0.18, alpha: 1),
               NSColor(red: 0.16, green: 0.79, blue: 0.25, alpha: 1)].enumerated() {
    c.setFill()
    NSBezierPath(ovalIn: NSRect(x: 14 + CGFloat(i) * 20, y: topY(10, 12), width: 12, height: 12)).fill()
}
text("DropJPG", W/2 - 28, 8, size: 13, weight: .semibold, color: GRAY)

let pad: CGFloat = 16
var y = TITLE + pad

// --- drop zone ---
let dzH: CGFloat = 110
let dz = box(pad, y, W - pad*2, dzH, 12)
NSColor.white.setFill(); dz.fill()
dz.lineWidth = 2; dz.setLineDash([8, 5], count: 2, phase: 0)
NSColor(calibratedWhite: 0.75, alpha: 1).setStroke(); dz.stroke()
// convert glyph: empty square → filled square + arrow
let gTop = y + 28
let gMid = topY(gTop + 14, 0)
GRAY.setStroke()
let sq = box(W/2 - 60, gTop, 28, 28, 6); sq.lineWidth = 3; sq.stroke()
GRAY.setFill(); box(W/2 + 34, gTop, 28, 28, 6).fill()
let ar = NSBezierPath()
ar.move(to: NSPoint(x: W/2 - 20, y: gMid)); ar.line(to: NSPoint(x: W/2 + 24, y: gMid))
ar.lineWidth = 4; GRAY.setStroke(); ar.stroke()
let head = NSBezierPath()
head.move(to: NSPoint(x: W/2 + 14, y: gMid + 8)); head.line(to: NSPoint(x: W/2 + 26, y: gMid))
head.line(to: NSPoint(x: W/2 + 14, y: gMid - 8)); GRAY.setFill(); head.fill()
text("여기로 파일/폴더를 끌어다 놓으세요", W/2 - 108, y + 78, size: 13, weight: .medium, color: GRAY)
y += dzH + 12

// --- count ---
text("끌어다 놓은 파일: 5개", pad + 2, y, size: 12, weight: .semibold, color: DARK)
y += 22

// --- file list ---
let listH: CGFloat = 100
let lb = box(pad, y, W - pad*2, listH, 4)
NSColor.white.setFill(); lb.fill()
NSColor(calibratedWhite: 0.80, alpha: 1).setStroke(); lb.lineWidth = 1; lb.stroke()
let files = ["• IMG_4821.HEIC", "• IMG_4822.HEIC", "• sunset.png", "• scan.webp", "• receipt.pdf"]
for (i, f) in files.enumerated() {
    text(f, pad + 10, y + 9 + CGFloat(i) * 17, size: 11, color: GRAY, mono: true)
}
y += listH + 14

// --- folder name field ---
text("폴더 이름", pad + 2, y, size: 12, weight: .semibold, color: DARK); y += 20
let f1 = box(pad, y, W - pad*2, 26, 5)
NSColor.white.setFill(); f1.fill(); NSColor(calibratedWhite: 0.75, alpha: 1).setStroke(); f1.lineWidth = 1; f1.stroke()
text("제주여행", pad + 9, y + 5, size: 13, color: DARK)
y += 38

// --- width field ---
text("가로 픽셀 (선택 — 비우면 원본 크기)", pad + 2, y, size: 12, weight: .semibold, color: DARK); y += 20
let f2 = box(pad, y, W - pad*2, 26, 5)
NSColor.white.setFill(); f2.fill(); NSColor(calibratedWhite: 0.75, alpha: 1).setStroke(); f2.lineWidth = 1; f2.stroke()
text("1920", pad + 9, y + 5, size: 13, color: DARK)
y += 40

// --- status ---
text("완료! 변환 4, 복사 1", pad + 2, y, size: 12, weight: .medium,
     color: NSColor(red: 0.16, green: 0.62, blue: 0.27, alpha: 1))

// --- buttons (bottom-right) ---
let byTop = H - 16 - 28
let convert = box(W - pad - 96, byTop, 96, 28, 6)
NSColor(red: 0.36, green: 0.45, blue: 0.95, alpha: 1).setFill(); convert.fill()
text("변환 시작", W - pad - 76, byTop + 7, size: 13, weight: .semibold, color: .white)
let clear = box(W - pad - 96 - 70, byTop, 60, 28, 6)
NSColor.white.setFill(); clear.fill(); NSColor(calibratedWhite: 0.75, alpha: 1).setStroke(); clear.lineWidth = 1; clear.stroke()
text("비우기", W - pad - 96 - 54, byTop + 7, size: 13, color: DARK)

NSGraphicsContext.restoreGraphicsState()
try! FileManager.default.createDirectory(atPath: "docs", withIntermediateDirectories: true)
let data = rep.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: "docs/screenshot.png"))
print("wrote docs/screenshot.png (\(Int(W*S))x\(Int(H*S)))")
