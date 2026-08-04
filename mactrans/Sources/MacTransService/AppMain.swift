import AppKit
import UserNotifications

/// Background agent that publishes the "翻譯成繁體中文" system service.
///
/// The app has no window and no Dock icon (`LSUIElement`). macOS launches it on
/// demand when the service is invoked from any app's Services menu, and it then
/// stays resident so later invocations skip the launch cost and so notification
/// action callbacks have somewhere to land.
@main
enum AppMain {
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let provider = ServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = provider
        NSUpdateDynamicServices()
        Notifier.shared.prepare()
        runSelfTestIfRequested()
    }

    /// `MacTransService --selftest <text>` exercises the translate-and-notify
    /// path without going through the Services menu, which cannot be driven
    /// programmatically. LaunchServices never passes arguments, so this is
    /// inert during normal use.
    private func runSelfTestIfRequested() {
        let arguments = CommandLine.arguments
        guard let flag = arguments.firstIndex(of: "--selftest") else { return }
        let text = arguments.dropFirst(flag + 1).joined(separator: " ")
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("MacTransSelfTest"))
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        provider.translateToTraditionalChinese(pasteboard, userData: nil, error: nil)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
