import Foundation

/// Shared by the app and extension. Raw values are stable preference identifiers.
nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system, arabic = "ar", english = "en"

    static let preferenceKey = "settings.language"
    var id: String { rawValue }

    static var current: Self {
        AppGroup.defaults
            .string(forKey: preferenceKey).flatMap(Self.init(rawValue:)) ?? .system
    }

    func resolvedCode(preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        guard self == .system else { return rawValue }
        return Bundle.preferredLocalizations(from: ["ar", "en"], forPreferences: preferredLanguages).first ?? "ar"
    }

    var locale: Locale { Locale(identifier: resolvedCode()) }
    var isRightToLeft: Bool { resolvedCode() == "ar" }
    var title: String {
        switch self {
        case .system: L10n.text("لغة الجهاز")
        case .arabic: "العربية"
        case .english: "English"
        }
    }
}

nonisolated enum L10n {
    /// Explicit bundle selection also localizes model strings when the in-app
    /// preference differs from the device language. Missing entries retain Arabic.
    static func text(_ key: String, language: AppLanguage = .current, bundle: Bundle = .main) -> String {
        guard let path = bundle.path(forResource: language.resolvedCode(), ofType: "lproj"),
              let localized = Bundle(path: path) else { return key }
        return localized.localizedString(forKey: key, value: key, table: "Localizable")
    }

    static func widgetCount(_ count: Int) -> String {
        let number = count.formatted(.number.locale(AppLanguage.current.locale))
        if AppLanguage.current.isRightToLeft { return "\(number) ودجت" }
        return "\(number) \(count == 1 ? "widget" : "widgets")"
    }
}
