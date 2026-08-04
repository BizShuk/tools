import Foundation
import Translation

/// How a result was produced.
public enum TranslationMethod: String, Sendable {
    /// Selection was already in the target language; returned untouched.
    case unchanged
    /// Simplified → Traditional handled by ICU, not by the translation engine.
    case scriptConversion
    /// Apple's on-device translation model did the work.
    case translationEngine
}

/// Outcome of one translation request.
public struct TranslationResult: Sendable {
    public let sourceLanguage: Locale.Language
    public let targetLanguage: Locale.Language
    public let sourceText: String
    public let targetText: String
    public let method: TranslationMethod
}

/// Translates text with Apple's on-device Translation engine.
///
/// This deliberately uses `Translation.framework` rather than the
/// `FoundationModels` general-purpose model: the general model applies content
/// guardrails that reject ordinary prose, and its translations are noticeably
/// worse than the dedicated translation models.
public struct Translator: Sendable {
    public static let traditionalChinese = Locale.Language(identifier: "zh-Hant")

    public let target: Locale.Language

    public init(target: Locale.Language = Translator.traditionalChinese) {
        self.target = target
    }

    public func translate(_ raw: String) async throws -> TranslationResult {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw TranslateError.emptyInput }

        let availability = LanguageAvailability()
        let supported = await availability.supportedLanguages
        guard let source = LanguageDetector(supported: supported).detect(text) else {
            throw TranslateError.undetectableSource
        }

        if source.isEquivalent(to: target) {
            return result(source: source, text: text, output: text, method: .unchanged)
        }

        // Chinese-to-Chinese never reaches the engine — see ChineseScriptConverter.
        if source.languageCode?.identifier == "zh", target.script?.identifier == "Hant" {
            return result(
                source: source,
                text: text,
                output: ChineseScriptConverter.simplifiedToTraditional(text),
                method: .scriptConversion
            )
        }

        switch await availability.status(from: source, to: target) {
        case .installed:
            break
        case .supported:
            throw TranslateError.packNotInstalled(
                source: source.displayName, target: target.displayName)
        case .unsupported:
            throw TranslateError.unsupportedPair(
                source: source.displayName, target: target.displayName)
        @unknown default:
            throw TranslateError.unsupportedPair(
                source: source.displayName, target: target.displayName)
        }

        let session = TranslationSession(installedSource: source, target: target)
        do {
            let response = try await session.translate(text)
            return TranslationResult(
                sourceLanguage: response.sourceLanguage,
                targetLanguage: response.targetLanguage,
                sourceText: text,
                targetText: response.targetText,
                method: .translationEngine
            )
        } catch {
            throw TranslateError.engineFailed(underlying: error)
        }
    }

    private func result(
        source: Locale.Language, text: String, output: String, method: TranslationMethod
    ) -> TranslationResult {
        TranslationResult(
            sourceLanguage: source,
            targetLanguage: target,
            sourceText: text,
            targetText: output,
            method: method
        )
    }
}

extension Locale.Language {
    /// Human-readable name in the user's own locale, for error messages.
    /// Uses the maximal identifier so `zh-Hans` and `zh-Hant` stay distinguishable.
    public var displayName: String {
        Locale.current.localizedString(forIdentifier: maximalIdentifier)
            ?? Locale.current.localizedString(forLanguageCode: languageCode?.identifier ?? "")
            ?? maximalIdentifier
    }
}
