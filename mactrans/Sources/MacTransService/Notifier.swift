import AppKit
import OSLog
import TranslateCore
import UserNotifications

/// Presents translation results to the user.
///
/// Preferred path is a Notification Center banner. Authorization is resolved at
/// post time rather than cached at launch — a translation can finish before the
/// permission prompt is answered, and a stale "not yet granted" would silently
/// downgrade every result. When notifications are genuinely unavailable the
/// result goes to a modal alert instead, so a translation is never lost.
@MainActor
final class Notifier: NSObject {
    static let shared = Notifier()

    nonisolated static let categoryIdentifier = "com.shuk.transzh.translation"
    nonisolated static let copyActionIdentifier = "copy"
    nonisolated static let payloadKey = "targetText"

    /// Registers the notification category and asks for permission.
    ///
    /// Asking at launch rather than on the first translation is deliberate: the
    /// installer launches the agent, so the prompt arrives while the user is
    /// still thinking about MacTrans and no translation has to race it.
    ///
    /// Killing the agent while that prompt is on screen records a permanent
    /// denial against the bundle id that cannot be cleared without Full Disk
    /// Access — so `scripts/install.sh` must not restart the agent after the
    /// launch that raises it.
    func prepare() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let copy = UNNotificationAction(
            identifier: Self.copyActionIdentifier,
            title: "複製翻譯",
            options: []
        )
        center.setNotificationCategories([
            UNNotificationCategory(
                identifier: Self.categoryIdentifier,
                actions: [copy],
                intentIdentifiers: [],
                options: []
            )
        ])

        Task { _ = await notificationsAllowed() }
    }

    /// A successful translation is shown bare: no title, no language pair, just
    /// the translated text. The banner already carries the MacTrans name and
    /// icon, so a "翻譯完成" header would only push the text the user actually
    /// wants further down. Source language and method stay available on the CLI
    /// via `mactrans -v`.
    func showResult(_ result: TranslationResult) async {
        await post(title: nil, body: result.targetText, payload: result.targetText)
    }

    /// Failures keep their title — an error has to be distinguishable from a
    /// translation at a glance.
    func showFailure(_ message: String) async {
        await post(title: "翻譯失敗", body: message, payload: nil)
    }

    private func post(title: String?, body: String, payload: String?) async {
        guard await notificationsAllowed() else {
            log("notifications unavailable, falling back to alert")
            showAlert(title: title, body: body, payload: payload)
            return
        }

        let content = UNMutableNotificationContent()
        if let title { content.title = title }
        content.body = body
        content.interruptionLevel = .active
        if let payload {
            content.categoryIdentifier = Self.categoryIdentifier
            content.userInfo = [Self.payloadKey: payload]
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil)
        do {
            try await UNUserNotificationCenter.current().add(request)
            log("posted notification: \(title ?? "(untitled)")")
        } catch {
            log("notification post failed: \(error.localizedDescription)")
            showAlert(title: title, body: body, payload: payload)
        }
    }

    private func notificationsAllowed() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        switch status {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                log("authorization request granted=\(granted)")
                return granted
            } catch {
                log("authorization request failed: \(error)")
                return false
            }
        default:
            log("authorization status=\(status.rawValue) (denied or restricted)")
            return false
        }
    }

    private func showAlert(title: String?, body: String, payload: String?) {
        let alert = NSAlert()
        // An untitled result puts the translation itself in the headline slot;
        // NSAlert renders an empty messageText as a blank gap.
        alert.messageText = title ?? body
        alert.informativeText = title == nil ? "" : body
        alert.addButton(withTitle: payload == nil ? "好" : "複製翻譯")
        if payload != nil { alert.addButton(withTitle: "關閉") }

        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn, let payload {
            copyToPasteboard(payload)
        }
    }

    fileprivate func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// LaunchServices starts this agent with no usable stdio, so diagnostics go
    /// to the unified log. Follow them with:
    ///   log stream --predicate 'subsystem == "com.shuk.transzh"'
    private static let logger = Logger(subsystem: "com.shuk.transzh", category: "notifier")

    private func log(_ message: String) {
        Self.logger.notice("\(message, privacy: .public)")
    }
}

extension Notifier: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == Self.copyActionIdentifier,
              let text = response.notification.request.content
                  .userInfo[Self.payloadKey] as? String
        else { return }
        await MainActor.run { Notifier.shared.copyToPasteboard(text) }
    }
}
