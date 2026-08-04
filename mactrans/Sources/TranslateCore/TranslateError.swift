import Foundation

/// Every failure mode the translation pipeline can surface to a caller.
public enum TranslateError: LocalizedError {
    /// Selection was empty or whitespace only.
    case emptyInput
    /// Source language could not be matched to any language the engine supports —
    /// either the text is too short to identify, or its language has no model.
    case undetectableSource
    /// Apple's Translation engine has no model pairing this source with the target.
    case unsupportedPair(source: String, target: String)
    /// The pairing exists but its language pack has not been downloaded yet.
    case packNotInstalled(source: String, target: String)
    /// The engine itself failed mid-translation.
    case engineFailed(underlying: any Error)

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "沒有選取任何文字。"
        case .undetectableSource:
            return "無法判斷來源語言。文字可能太短，或該語言不在系統翻譯的支援清單內。"
        case let .unsupportedPair(source, target):
            return "系統翻譯不支援 \(source) → \(target)。"
        case let .packNotInstalled(source, target):
            return "尚未下載 \(source) → \(target) 語言包。請到「系統設定 › 一般 › 語言與地區 › 翻譯語言」下載。"
        case let .engineFailed(underlying):
            return "翻譯失敗：\(underlying.localizedDescription)"
        }
    }
}
