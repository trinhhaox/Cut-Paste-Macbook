import Foundation

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case english = "en"
    case vietnamese = "vi"

    // Native names are intentionally not localized so users can always
    // recognize their own language in the picker.
    var displayName: String {
        switch self {
        case .system: return L.t("menu.language.system")
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }
}

// Localization helper with runtime language override.
// Strings live in <lang>.lproj/Localizable.strings.
// Usage: L.t("menu.quit") or L.t("menu.pending_count", count)
enum L {
    static let languageChanged = Notification.Name("CutPasteLanguageChanged")
    private static let defaultsKey = "AppLanguage"

    static var current: AppLanguage {
        get {
            guard let raw = UserDefaults.standard.string(forKey: defaultsKey),
                  let lang = AppLanguage(rawValue: raw) else { return .system }
            return lang
        }
        set {
            if newValue == .system {
                UserDefaults.standard.removeObject(forKey: defaultsKey)
            } else {
                UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
            }
            cachedBundle = resolveBundle()
            NotificationCenter.default.post(name: languageChanged, object: nil)
        }
    }

    private static var cachedBundle: Bundle = resolveBundle()

    private static func resolveBundle() -> Bundle {
        let lang = current
        guard lang != .system,
              let path = Bundle.main.path(forResource: lang.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // .system: Bundle.main follows the macOS preferred language.
            return Bundle.main
        }
        return bundle
    }

    static func t(_ key: String) -> String {
        cachedBundle.localizedString(forKey: key, value: nil, table: nil)
    }

    static func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: cachedBundle.localizedString(forKey: key, value: nil, table: nil), arguments: args)
    }
}
