import Foundation
import TranslateCore

/// Thin command-line front end over `TranslateCore`.
///
/// Reads the text to translate from the arguments, or from stdin when no text
/// argument is given, and writes the translation to stdout.
@main
struct CLI {
    static func main() async {
        var target = Translator.traditionalChinese
        var verbose = false
        var words: [String] = []

        var arguments = Array(CommandLine.arguments.dropFirst())
        while !arguments.isEmpty {
            let argument = arguments.removeFirst()
            switch argument {
            case "-h", "--help":
                print(usage)
                exit(0)
            case "-v", "--verbose":
                verbose = true
            case "-t", "--target":
                guard let value = arguments.first, !value.isEmpty else {
                    fail("--target 需要一個語言代碼，例如 zh-Hant。")
                }
                arguments.removeFirst()
                target = Locale.Language(identifier: value)
            default:
                words.append(argument)
            }
        }

        let input = words.isEmpty ? readStdin() : words.joined(separator: " ")

        do {
            let result = try await Translator(target: target).translate(input)
            if verbose {
                FileHandle.standardError.write(Data(
                    "\(result.sourceLanguage.maximalIdentifier) → \(result.targetLanguage.maximalIdentifier) [\(result.method.rawValue)]\n".utf8))
            }
            print(result.targetText)
        } catch {
            fail(error.localizedDescription)
        }
    }

    private static func readStdin() -> String {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("mactrans: \(message)\n".utf8))
        exit(1)
    }

    private static let usage = """
        mactrans — 用 macOS 內建 Translation 引擎翻譯文字（預設繁體中文）

        用法:
          mactrans [選項] [文字...]
          echo "text" | mactrans [選項]

        選項:
          -t, --target <lang>   目標語言代碼（預設 zh-Hant）
          -v, --verbose         在 stderr 印出偵測到的來源語言
          -h, --help            顯示此說明
        """
}
