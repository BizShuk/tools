import Foundation

/// Converts Simplified Chinese to Traditional Chinese.
///
/// Apple's Translation engine reports every Chinese-to-Chinese pair as
/// `unsupported`, so a Simplified selection has to go through ICU's
/// `Simplified-Traditional` transform instead. That transform is
/// character-level: it fixes the script but not regional word choice
/// (`計算機` stays `計算機`, it does not become Taiwan's `電腦`).
public enum ChineseScriptConverter {
    public static func simplifiedToTraditional(_ text: String) -> String {
        let buffer = CFStringCreateMutableCopy(nil, 0, text as CFString)!
        CFStringTransform(buffer, nil, "Simplified-Traditional" as CFString, false)
        return buffer as String
    }
}
