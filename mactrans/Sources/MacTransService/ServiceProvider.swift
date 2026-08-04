import AppKit
import TranslateCore

/// Bridges the macOS Services menu to `TranslateCore`.
///
/// The selector name here must stay in sync with `NSMessage` in Info.plist —
/// macOS looks the method up by name at invocation time, so a rename that
/// touches only one side fails silently with "服務無回應".
final class ServiceProvider: NSObject {
    private let translator = Translator()

    @objc func translateToTraditionalChinese(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString>?
    ) {
        let text = pasteboard.string(forType: .string) ?? ""
        let translator = self.translator

        // The service call must return promptly; translation continues detached.
        Task { @MainActor in
            do {
                let result = try await translator.translate(text)
                await Notifier.shared.showResult(result)
            } catch {
                await Notifier.shared.showFailure(error.localizedDescription)
            }
        }
    }
}
