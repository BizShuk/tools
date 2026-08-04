import Foundation
import NaturalLanguage

/// Identifies the source language of a selection.
///
/// Raw `NLLanguageRecognizer` output drifts on short strings, so detection is
/// constrained to the languages Apple's Translation engine can actually handle.
/// Anything outside that set is noise for our purposes.
public struct LanguageDetector: Sendable {
    private let candidates: [NLLanguage]

    /// - Parameter supported: languages the translation engine advertises, in
    ///   `Locale.Language` form. Region and script subtags are dropped; the
    ///   recognizer works at the language level.
    public init(supported: [Locale.Language]) {
        var seen = Set<String>()
        var codes: [NLLanguage] = []
        for language in supported {
            // Chinese needs its script subtag kept — Hans and Hant are distinct
            // recognizer outputs and distinct translation models.
            let identifier: String
            if language.languageCode?.identifier == "zh" {
                identifier = "zh-\(language.script?.identifier ?? "Hans")"
            } else if let code = language.languageCode?.identifier {
                identifier = code
            } else {
                continue
            }
            guard seen.insert(identifier).inserted else { continue }
            codes.append(NLLanguage(identifier))
        }
        self.candidates = codes
    }

    /// Returns the dominant language of `text`, or `nil` when the recognizer
    /// cannot commit to one of the candidates.
    public func detect(_ text: String) -> Locale.Language? {
        let recognizer = NLLanguageRecognizer()
        recognizer.languageConstraints = candidates
        recognizer.processString(text)
        guard let dominant = recognizer.dominantLanguage else { return nil }
        return Locale.Language(identifier: dominant.rawValue)
    }
}
