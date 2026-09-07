import Cocoa
import SwiftUI
import Carbon
import ApplicationServices

/// A selectable shortcut for the "Read selection" action.
struct ReadShortcut {
    let id: String
    let label: String
    let keyCode: UInt32
    let modifiers: UInt32
}

let readShortcutPresets: [ReadShortcut] = [
    ReadShortcut(id: "opt-cmd-r", label: "⌥⌘R", keyCode: 15, modifiers: UInt32(optionKey | cmdKey)),
    ReadShortcut(id: "opt-cmd-e", label: "⌥⌘E", keyCode: 14, modifiers: UInt32(optionKey | cmdKey)),
    ReadShortcut(id: "ctrl-opt-r", label: "⌃⌥R", keyCode: 15, modifiers: UInt32(controlKey | optionKey)),
    ReadShortcut(id: "ctrl-opt-s", label: "⌃⌥S", keyCode: 1, modifiers: UInt32(controlKey | optionKey)),
    ReadShortcut(id: "ctrl-cmd-r", label: "⌃⌘R", keyCode: 15, modifiers: UInt32(controlKey | cmdKey)),
    ReadShortcut(id: "ctrl-opt-space", label: "⌃⌥Space", keyCode: 49, modifiers: UInt32(controlKey | optionKey)),
]

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var hotKeySpeak: EventHotKeyRef?
    var hotKeyFaster: EventHotKeyRef?
    var hotKeySlower: EventHotKeyRef?
    var bannerWindow: NSWindow?

    var currentReadShortcut: ReadShortcut {
        let id = UserDefaults.standard.string(forKey: "readShortcutID") ?? "opt-cmd-r"
        return readShortcutPresets.first { $0.id == id } ?? readShortcutPresets[0]
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        SpeechReader.shared.onRateChange = { [weak self] _ in
            DispatchQueue.main.async { self?.updateIcon() }
        }

        updateIcon()
        registerHotKeys()
        promptForAccessibilityIfNeeded()
    }

    // MARK: - Accessibility permission (needed to send ⌘C)

    func promptForAccessibilityIfNeeded() {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )
        if !trusted {
            // The system prompt is shown automatically by the call above.
            // Nothing else to do; user grants it in System Settings.
        }
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let label = "\(SpeechReader.shared.wpm()) wpm"
        let title = NSMenuItem(title: "Speed: \(label)", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)

        menu.addItem(.separator())

        let speak = NSMenuItem(title: "Speak Selection / Stop  \(currentReadShortcut.label)", action: #selector(speakTapped), keyEquivalent: "")
        speak.target = self
        menu.addItem(speak)

        let faster = NSMenuItem(title: "Faster  ⌥⌘→", action: #selector(fasterTapped), keyEquivalent: "")
        faster.target = self
        menu.addItem(faster)

        let slower = NSMenuItem(title: "Slower  ⌥⌘←", action: #selector(slowerTapped), keyEquivalent: "")
        slower.target = self
        menu.addItem(slower)

        menu.addItem(.separator())

        let reset = NSMenuItem(title: "Reset Speed", action: #selector(resetTapped), keyEquivalent: "")
        reset.target = self
        menu.addItem(reset)

        // Read shortcut submenu
        let scItem = NSMenuItem(title: "Read Shortcut", action: nil, keyEquivalent: "")
        let scMenu = NSMenu()
        for preset in readShortcutPresets {
            let mi = NSMenuItem(title: preset.label, action: #selector(changeReadShortcut(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = preset.id
            mi.state = (preset.id == currentReadShortcut.id) ? .on : .off
            scMenu.addItem(mi)
        }
        scItem.submenu = scMenu
        menu.addItem(scItem)

        let access = NSMenuItem(title: "Open Accessibility Settings…", action: #selector(openAccessibility), keyEquivalent: "")
        access.target = self
        menu.addItem(access)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc func speakTapped() { handleSpeak() }
    @objc func fasterTapped() { handleRate(faster: true) }
    @objc func slowerTapped() { handleRate(faster: false) }

    @objc func resetTapped() {
        // Reset by stepping toward 0.5
        while SpeechReader.shared.rate < 0.49 { SpeechReader.shared.increase() }
        while SpeechReader.shared.rate > 0.51 { SpeechReader.shared.decrease() }
        updateIcon()
        showBanner(top: "Speed", big: "\(SpeechReader.shared.wpm()) wpm", sub: nil)
    }

    @objc func openAccessibility() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Actions

    func handleSpeak() {
        if SpeechReader.shared.isSpeaking {
            SpeechReader.shared.stop()
            showBanner(top: nil, big: "Stopped", sub: nil)
            return
        }
        SelectionReader.capture { [weak self] text in
            guard let self = self else { return }
            guard let text = text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                self.showBanner(top: nil, big: "No text selected", sub: "Select text, then \(self.currentReadShortcut.label)")
                return
            }
            SpeechReader.shared.speak(text)
            self.showBanner(top: "Reading", big: "\(SpeechReader.shared.wpm()) wpm", sub: nil)
        }
    }

    func handleRate(faster: Bool) {
        if faster { SpeechReader.shared.increase() } else { SpeechReader.shared.decrease() }
        updateIcon()
        let sub = SpeechReader.shared.isSpeaking ? "Applied live" : nil
        showBanner(top: "Speed", big: "\(SpeechReader.shared.wpm()) wpm", sub: sub)
    }

    // MARK: - Icon

    func updateIcon() {
        if let button = statusItem.button {
            button.image = makeIcon()
            button.toolTip = "Speed: \(SpeechReader.shared.wpm()) wpm"
        }
    }

    func makeIcon() -> NSImage {
        let label = "\(SpeechReader.shared.wpm())"
        let h: CGFloat = 18
        let glyphW: CGFloat = 18
        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        let textW = (label as NSString).size(withAttributes: [.font: font]).width
        let width = glyphW + textW + 4

        let image = NSImage(size: NSSize(width: width, height: h), flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let color = NSColor.black

            // Mini speaker + single chevron (matches app icon identity)
            ctx.setFillColor(color.cgColor)
            ctx.setStrokeColor(color.cgColor)
            let cy = rect.midY
            let u: CGFloat = 7
            let bx: CGFloat = 1.5
            // speaker box
            ctx.fill(CGRect(x: bx, y: cy - u*0.28, width: u*0.32, height: u*0.56))
            // cone
            let cone = CGMutablePath()
            cone.move(to: CGPoint(x: bx + u*0.32, y: cy - u*0.28))
            cone.addLine(to: CGPoint(x: bx + u*0.78, y: cy - u*0.55))
            cone.addLine(to: CGPoint(x: bx + u*0.78, y: cy + u*0.55))
            cone.addLine(to: CGPoint(x: bx + u*0.32, y: cy + u*0.28))
            cone.closeSubpath()
            ctx.addPath(cone); ctx.fillPath()
            // chevron
            ctx.setLineWidth(1.4); ctx.setLineCap(.round); ctx.setLineJoin(.round)
            let chx = bx + u*0.95
            let ch = CGMutablePath()
            ch.move(to: CGPoint(x: chx, y: cy + u*0.45))
            ch.addLine(to: CGPoint(x: chx + u*0.45, y: cy))
            ch.addLine(to: CGPoint(x: chx, y: cy - u*0.45))
            ctx.addPath(ch); ctx.strokePath()

            // wpm number
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
            let str = NSAttributedString(string: label, attributes: attrs)
            str.draw(at: NSPoint(x: glyphW, y: cy - str.size().height/2))
            return true
        }
        image.isTemplate = true
        return image
    }

    // MARK: - Banner

    func showBanner(top: String?, big: String, sub: String?) {
        bannerWindow?.orderOut(nil)
        bannerWindow = nil

        let screen = statusItem.button?.window?.screen ?? NSScreen.main
        guard let screen = screen else { return }

        let view = BannerView(top: top, big: big, sub: sub)
        let hosting = NSHostingView(rootView: view)
        let size = hosting.fittingSize
        let width = max(size.width + 32, 180)
        let height = size.height + 20
        let sf = screen.frame
        let x = sf.midX - width / 2
        let y = sf.maxY - height - 6

        let win = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]
        win.contentView = NSHostingView(rootView: view)
        win.orderFrontRegardless()
        bannerWindow = win

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.bannerWindow?.orderOut(nil)
            self?.bannerWindow = nil
        }
    }

    // MARK: - Hotkeys

    @objc func changeReadShortcut(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        UserDefaults.standard.set(id, forKey: "readShortcutID")
        // Unregister the old read hotkey and re-register with the new combo
        if let ref = hotKeySpeak { UnregisterEventHotKey(ref); hotKeySpeak = nil }
        let sc = currentReadShortcut
        var idSpeak = EventHotKeyID(); idSpeak.signature = OSType("SPSP".fourCharCode); idSpeak.id = 1
        RegisterEventHotKey(sc.keyCode, sc.modifiers, idSpeak, GetApplicationEventTarget(), 0, &hotKeySpeak)
        showBanner(top: "Read shortcut", big: sc.label, sub: nil)
    }

    func registerHotKeys() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Read/stop — configurable
        let sc = currentReadShortcut
        var idSpeak = EventHotKeyID(); idSpeak.signature = OSType("SPSP".fourCharCode); idSpeak.id = 1
        RegisterEventHotKey(sc.keyCode, sc.modifiers, idSpeak, GetApplicationEventTarget(), 0, &hotKeySpeak)

        // ⌥⌘→ — faster (keyCode 124)
        var idFast = EventHotKeyID(); idFast.signature = OSType("SPFA".fourCharCode); idFast.id = 2
        RegisterEventHotKey(124, UInt32(optionKey | cmdKey), idFast, GetApplicationEventTarget(), 0, &hotKeyFaster)

        // ⌥⌘← — slower (keyCode 123)
        var idSlow = EventHotKeyID(); idSlow.signature = OSType("SPSL".fourCharCode); idSlow.id = 3
        RegisterEventHotKey(123, UInt32(optionKey | cmdKey), idSlow, GetApplicationEventTarget(), 0, &hotKeySlower)

        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            guard let event = event else { return noErr }
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            let d = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            DispatchQueue.main.async {
                switch hkID.id {
                case 1: d.handleSpeak()
                case 2: d.handleRate(faster: true)
                case 3: d.handleRate(faster: false)
                default: break
                }
            }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }
}

// MARK: - Banner SwiftUI View

struct BannerView: View {
    let top: String?
    let big: String
    let sub: String?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            VStack(alignment: .leading, spacing: 2) {
                if let top = top {
                    Text(top)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
                Text(big)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                if let sub = sub {
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.82))
        )
    }
}

extension String {
    var fourCharCode: FourCharCode {
        return self.utf16.reduce(0) { $0 << 8 + FourCharCode($1) }
    }
}
