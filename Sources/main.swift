// PhotoRename — macOS menu bar app.
// Click the status bar icon → "사진 변환…" → drop files/folders, type a name,
// and every image is converted to JPG into ~/Desktop/<name>/<name>_001.jpg, ...
// Non-image files are copied as-is with the same numbering.

import Cocoa
import UniformTypeIdentifiers

// MARK: - Image handling

let imageExtensions: Set<String> = [
    "jpg", "jpeg", "png", "gif", "bmp", "tif", "tiff",
    "webp", "heic", "heif", "raw", "cr2", "nef", "arw", "dng",
]

/// Recursively expand a list of dropped URLs into a flat, sorted list of files.
func collectFiles(from urls: [URL]) -> [URL] {
    let fm = FileManager.default
    var files: [URL] = []
    for url in urls {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { continue }
        if isDir.boolValue {
            if let en = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey]) {
                for case let child as URL in en {
                    var childIsDir: ObjCBool = false
                    if fm.fileExists(atPath: child.path, isDirectory: &childIsDir), !childIsDir.boolValue {
                        if !child.lastPathComponent.hasPrefix(".") {
                            files.append(child)
                        }
                    }
                }
            }
        } else if !url.lastPathComponent.hasPrefix(".") {
            files.append(url)
        }
    }
    return files.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
}

struct ProcessResult {
    var converted = 0
    var copied = 0
    var failed = 0
    var destination: URL?
    var error: String?
}

/// Convert one image to JPEG via the built-in `sips` tool.
/// `width` (optional) resamples to that pixel width, preserving aspect ratio.
@discardableResult
func sipsConvert(_ src: URL, to dst: URL, width: Int? = nil) -> Bool {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    var args = ["-s", "format", "jpeg"]
    if let w = width { args += ["--resampleWidth", String(w)] }
    args += [src.path, "--out", dst.path]
    task.arguments = args
    task.standardOutput = Pipe()
    task.standardError = Pipe()
    do {
        try task.run()
        task.waitUntilExit()
        return task.terminationStatus == 0
    } catch {
        return false
    }
}

/// Make ~/Desktop/<name>, converting/copying files in numbered order.
/// `targetWidth` (optional) resizes every image to that pixel width, aspect preserved.
func runConversion(urls: [URL], name: String, targetWidth: Int? = nil) -> ProcessResult {
    var result = ProcessResult()
    let fm = FileManager.default

    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    let safeName = trimmed.isEmpty ? "photo" : trimmed
        .replacingOccurrences(of: "/", with: "-")
        .replacingOccurrences(of: ":", with: "-")

    let desktop = fm.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    var dest = desktop.appendingPathComponent(safeName)
    // Avoid clobbering an existing folder.
    var n = 2
    while fm.fileExists(atPath: dest.path) {
        dest = desktop.appendingPathComponent("\(safeName) (\(n))")
        n += 1
    }
    do {
        try fm.createDirectory(at: dest, withIntermediateDirectories: true)
    } catch {
        result.error = "폴더 생성 실패: \(error.localizedDescription)"
        return result
    }
    result.destination = dest

    let files = collectFiles(from: urls)
    if files.isEmpty {
        result.error = "처리할 파일이 없습니다."
        return result
    }

    let pad = max(3, String(files.count).count)
    var index = 1
    for src in files {
        let ext = src.pathExtension.lowercased()
        let stem = String(format: "%@_%0\(pad)d", safeName, index)
        if imageExtensions.contains(ext) {
            let dst = dest.appendingPathComponent("\(stem).jpg")
            if sipsConvert(src, to: dst, width: targetWidth) {
                result.converted += 1
            } else {
                result.failed += 1
            }
        } else {
            let dst = dest.appendingPathComponent("\(stem).\(ext.isEmpty ? "dat" : ext)")
            do {
                try fm.copyItem(at: src, to: dst)
                result.copied += 1
            } catch {
                result.failed += 1
            }
        }
        index += 1
    }
    return result
}

// MARK: - Drop view

final class DropView: NSView {
    var onDrop: (([URL]) -> Void)?
    private var highlighted = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    override func draw(_ dirtyRect: NSRect) {
        let bg = highlighted
            ? NSColor.controlAccentColor.withAlphaComponent(0.18)
            : NSColor.textBackgroundColor.withAlphaComponent(0.5)
        bg.setFill()
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 8, dy: 8), xRadius: 12, yRadius: 12)
        path.fill()
        path.lineWidth = 2
        let dash: [CGFloat] = [8, 5]
        path.setLineDash(dash, count: 2, phase: 0)
        (highlighted ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
        path.stroke()
    }

    private func urls(from sender: NSDraggingInfo) -> [URL] {
        let opts: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let objs = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: opts)
        return (objs as? [URL]) ?? []
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        highlighted = !urls(from: sender).isEmpty
        needsDisplay = true
        return highlighted ? .copy : []
    }
    override func draggingExited(_ sender: NSDraggingInfo?) {
        highlighted = false
        needsDisplay = true
    }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        highlighted = false
        needsDisplay = true
        let dropped = urls(from: sender)
        guard !dropped.isEmpty else { return false }
        onDrop?(dropped)
        return true
    }
}

// MARK: - Drop window controller

final class DropWindowController: NSWindowController {
    private let dropView = DropView(frame: .zero)
    private let countLabel = NSTextField(labelWithString: "끌어다 놓은 파일: 0개")
    private let listScroll = NSScrollView()
    private let listText = NSTextView()
    private let nameField = NSTextField(string: "")
    private let widthField = NSTextField(string: "")
    private let statusLabel = NSTextField(labelWithString: "")
    private let convertButton = NSButton(title: "변환 시작", target: nil, action: nil)
    private var droppedURLs: [URL] = []

    convenience init() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        win.title = "DropJPG"
        win.isReleasedWhenClosed = false
        win.level = .floating // always stay above other windows so drag-drop never hides it
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.init(window: win)
        buildUI()
    }

    private func buildUI() {
        guard let content = window?.contentView else { return }

        let hint = NSTextField(labelWithString: "여기로 파일/폴더를 끌어다 놓으세요")
        hint.font = .systemFont(ofSize: 14, weight: .medium)
        hint.alignment = .center
        hint.textColor = .secondaryLabelColor

        dropView.onDrop = { [weak self] urls in
            guard let self = self else { return }
            self.droppedURLs.append(contentsOf: urls)
            self.refreshList()
            self.statusLabel.stringValue = ""
        }

        countLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        countLabel.textColor = .labelColor

        // scrollable list of dropped file names
        listText.isEditable = false
        listText.isSelectable = true
        listText.drawsBackground = false
        listText.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        listText.textContainerInset = NSSize(width: 6, height: 6)
        listText.textColor = .secondaryLabelColor
        listScroll.documentView = listText
        listScroll.hasVerticalScroller = true
        listScroll.borderType = .lineBorder
        listScroll.drawsBackground = true
        listScroll.backgroundColor = .textBackgroundColor

        let nameTitle = NSTextField(labelWithString: "폴더 이름")
        nameTitle.font = .systemFont(ofSize: 12, weight: .semibold)
        nameField.placeholderString = "예: 제주여행"
        nameField.font = .systemFont(ofSize: 13)

        let widthTitle = NSTextField(labelWithString: "가로 픽셀 (선택 — 비우면 원본 크기)")
        widthTitle.font = .systemFont(ofSize: 12, weight: .semibold)
        widthField.placeholderString = "예: 1920"
        widthField.font = .systemFont(ofSize: 13)

        convertButton.bezelStyle = .rounded
        convertButton.keyEquivalent = "\r"
        convertButton.target = self
        convertButton.action = #selector(convertTapped)

        let clearButton = NSButton(title: "비우기", target: self, action: #selector(clearTapped))
        clearButton.bezelStyle = .rounded

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.maximumNumberOfLines = 3

        for v in [dropView, countLabel, listScroll, nameTitle, nameField,
                  widthTitle, widthField, statusLabel, convertButton, clearButton] {
            v.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(v)
        }
        // Put the hint label centered on the drop view.
        hint.translatesAutoresizingMaskIntoConstraints = false
        dropView.addSubview(hint)

        NSLayoutConstraint.activate([
            dropView.topAnchor.constraint(equalTo: content.topAnchor, constant: 16),
            dropView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            dropView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            dropView.heightAnchor.constraint(equalToConstant: 110),

            hint.centerXAnchor.constraint(equalTo: dropView.centerXAnchor),
            hint.centerYAnchor.constraint(equalTo: dropView.centerYAnchor),

            countLabel.topAnchor.constraint(equalTo: dropView.bottomAnchor, constant: 8),
            countLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 18),

            listScroll.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 6),
            listScroll.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            listScroll.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            listScroll.heightAnchor.constraint(equalToConstant: 110),

            nameTitle.topAnchor.constraint(equalTo: listScroll.bottomAnchor, constant: 14),
            nameTitle.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 18),

            nameField.topAnchor.constraint(equalTo: nameTitle.bottomAnchor, constant: 6),
            nameField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),

            widthTitle.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 12),
            widthTitle.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 18),

            widthField.topAnchor.constraint(equalTo: widthTitle.bottomAnchor, constant: 6),
            widthField.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            widthField.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),

            statusLabel.topAnchor.constraint(equalTo: widthField.bottomAnchor, constant: 14),
            statusLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 18),
            statusLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -18),

            convertButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -16),
            convertButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            clearButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -16),
            clearButton.trailingAnchor.constraint(equalTo: convertButton.leadingAnchor, constant: -10),
        ])
    }

    /// Rebuild the count label + file-name list from current drops.
    private func refreshList() {
        let files = collectFiles(from: droppedURLs)
        countLabel.stringValue = "끌어다 놓은 파일: \(files.count)개"
        listText.string = files.map { "• " + $0.lastPathComponent }.joined(separator: "\n")
    }

    @objc private func clearTapped() {
        droppedURLs.removeAll()
        refreshList()
        statusLabel.stringValue = ""
    }

    @objc private func convertTapped() {
        let urls = droppedURLs
        let name = nameField.stringValue
        if urls.isEmpty {
            statusLabel.textColor = .systemRed
            statusLabel.stringValue = "먼저 파일이나 폴더를 끌어다 놓으세요."
            return
        }
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            statusLabel.textColor = .systemRed
            statusLabel.stringValue = "폴더 이름을 입력하세요."
            return
        }
        // optional target width
        let widthText = widthField.stringValue.trimmingCharacters(in: .whitespaces)
        var targetWidth: Int? = nil
        if !widthText.isEmpty {
            guard let w = Int(widthText), w > 0 else {
                statusLabel.textColor = .systemRed
                statusLabel.stringValue = "가로 픽셀은 양의 정수여야 합니다."
                return
            }
            targetWidth = w
        }
        convertButton.isEnabled = false
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.stringValue = "변환 중…"

        DispatchQueue.global(qos: .userInitiated).async {
            let res = runConversion(urls: urls, name: name, targetWidth: targetWidth)
            DispatchQueue.main.async {
                self.convertButton.isEnabled = true
                if let err = res.error {
                    self.statusLabel.textColor = .systemRed
                    self.statusLabel.stringValue = err
                    return
                }
                self.statusLabel.textColor = .systemGreen
                var msg = "완료! 변환 \(res.converted), 복사 \(res.copied)"
                if res.failed > 0 { msg += ", 실패 \(res.failed)" }
                self.statusLabel.stringValue = msg
                if let dest = res.destination {
                    NSWorkspace.shared.activateFileViewerSelecting([dest])
                }
                self.droppedURLs.removeAll()
                self.refreshList()
            }
        }
    }

    func present() {
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }

    /// Populate fields with sample content for documentation screenshots.
    func fillDemo() {
        let samples = ["IMG_4821.HEIC", "IMG_4822.HEIC", "sunset.png", "scan.webp", "receipt.pdf"]
        countLabel.stringValue = "끌어다 놓은 파일: \(samples.count)개"
        listText.string = samples.map { "• " + $0 }.joined(separator: "\n")
        nameField.stringValue = "제주여행"
        widthField.stringValue = "1920"
        statusLabel.textColor = .systemGreen
        statusLabel.stringValue = "완료! 변환 4, 복사 1"
    }
}

// MARK: - App delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var dropController: DropWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // NSImage(named:) auto-resolves menubar.png / menubar@2x.png for retina.
            let img = NSImage(named: "menubar")
                ?? NSImage(systemSymbolName: "photo.on.rectangle.angled", accessibilityDescription: "DropJPG")
            img?.size = NSSize(width: 18, height: 18)
            img?.isTemplate = true // tint to match menu bar (light/dark)
            button.image = img
        }
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "사진 변환…", action: #selector(openDropWindow), keyEquivalent: "n"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "종료", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu

        // Screenshot mode: auto-open the window with sample data (for README/docs).
        if ProcessInfo.processInfo.environment["DROPJPG_AUTOSHOW"] == "1" {
            openDropWindow()
            dropController?.fillDemo()
        }
    }

    @objc private func openDropWindow() {
        if dropController == nil {
            dropController = DropWindowController()
        }
        dropController?.present()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // menu bar agent, no Dock icon
let delegate = AppDelegate()
app.delegate = delegate
app.run()
