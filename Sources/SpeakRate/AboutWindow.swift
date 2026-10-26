import Cocoa
import SwiftUI

/// Small floating About panel: version, author, blog and license.
enum AboutWindow {
    private static var window: NSWindow?

    static let githubURL = "https://github.com/augustose/SpeakRate"
    static let whatsNewURL = "https://github.com/augustose/SpeakRate/blob/main/CHANGELOG.md"
    static let blogURL = "https://augustose.web.app"
    static let email = "augustose@senet.ca"

    static func show() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingView(rootView: AboutView())
        let size = hosting.fittingSize
        let win = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title = "About \(appName)"
        win.contentView = hosting
        win.isReleasedWhenClosed = false
        win.center()
        win.level = .floating
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = win
    }

    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "SpeakRate"
    }

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}

private struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

            VStack(spacing: 3) {
                Text(AboutWindow.appName)
                    .font(.title2.bold())
                Text("Version \(AboutWindow.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Made with love, for everyone, for free.\nBecause good tools should just exist.")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Divider()
                .frame(width: 200)

            HStack(spacing: 18) {
                Link("Blog", destination: URL(string: AboutWindow.blogURL)!)
                Link("GitHub", destination: URL(string: AboutWindow.githubURL)!)
                Link("What's New", destination: URL(string: AboutWindow.whatsNewURL)!)
                Link("Email", destination: URL(string: "mailto:\(AboutWindow.email)")!)
            }
            .font(.system(size: 12, weight: .medium))

            Text("MIT licensed — free for everyone, forever.")
                .font(.system(size: 10))
                .foregroundColor(Color.secondary.opacity(0.8))
        }
        .padding(.vertical, 26)
        .padding(.horizontal, 24)
        .frame(width: 340)
    }
}
