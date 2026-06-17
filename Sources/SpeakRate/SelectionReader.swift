import AppKit
import Carbon

/// Captures the currently selected text in the frontmost app by simulating ⌘C,
/// reading the pasteboard, then restoring the previous pasteboard contents.
enum SelectionReader {

    /// Captures the selection asynchronously (waits for the hotkey modifiers to be
    /// released first, then polls the pasteboard). Calls `completion` on the main queue.
    static func capture(completion: @escaping (String?) -> Void) {
        let pasteboard = NSPasteboard.general
        let saved = pasteboard.string(forType: .string)
        let savedChangeCount = pasteboard.changeCount

        waitForModifiersReleased {
            pressCmdC()
            pollPasteboard(since: savedChangeCount, attempts: 20) { copied in
                if let saved = saved {
                    pasteboard.clearContents()
                    pasteboard.setString(saved, forType: .string)
                }
                DispatchQueue.main.async { completion(copied) }
            }
        }
    }

    /// Wait until the physical ⌥/⌘ from the hotkey are released, so our synthetic
    /// ⌘C isn't merged into ⌥⌘C.
    private static func waitForModifiersReleased(_ done: @escaping () -> Void) {
        func check(_ remaining: Int) {
            let flags = NSEvent.modifierFlags
            let stillDown = flags.contains(.command) || flags.contains(.option)
            if !stillDown || remaining == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03, execute: done)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { check(remaining - 1) }
            }
        }
        check(25)
    }

    private static func pollPasteboard(since oldCount: Int, attempts: Int,
                                       completion: @escaping (String?) -> Void) {
        let pb = NSPasteboard.general
        func attempt(_ n: Int) {
            if pb.changeCount != oldCount {
                completion(pb.string(forType: .string))
            } else if n == 0 {
                completion(nil)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { attempt(n - 1) }
            }
        }
        attempt(attempts)
    }

    private static func pressCmdC() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let cKey: CGKeyCode = 8 // 'c'

        let down = CGEvent(keyboardEventSource: src, virtualKey: cKey, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: src, virtualKey: cKey, keyDown: false)
        up?.flags = .maskCommand

        down?.post(tap: .cgAnnotatedSessionEventTap)
        up?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
