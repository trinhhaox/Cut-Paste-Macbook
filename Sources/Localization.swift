import Foundation

// Small localization helper. Strings live in <lang>.lproj/Localizable.strings.
// Usage: L.t("menu.quit") or L.t("menu.pending_count", count)
enum L {
    static func t(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: NSLocalizedString(key, comment: ""), arguments: args)
    }
}
