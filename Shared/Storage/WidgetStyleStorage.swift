//
//  WidgetStyleStorage.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Foundation

/// أشكال الودجات المحفوظة في المساحة المشتركة: التطبيق يكتبها، والـ Widget يقرأها عند الرسم.
/// كل نوع محفوظ منفصلاً، فلو تلف واحد ما تتأثر البقية.
nonisolated enum WidgetStyleStorage {
    private static let key = "widget.styles"

    /// شكل النوع إن خصّصه المستخدم، وإلا الشكل الافتراضي من الإعدادات
    static func style(for kindID: String, in defaults: UserDefaults = AppGroup.defaults) -> WidgetStyle {
        customStyle(for: kindID, in: defaults) ?? defaultStyle(in: defaults)
    }

    /// الشكل المحفوظ لهذا النوع فقط؛ nil إذا لم يخصّصه المستخدم
    static func customStyle(for kindID: String, in defaults: UserDefaults = AppGroup.defaults) -> WidgetStyle? {
        stored(in: defaults)[kindID].flatMap { try? JSONDecoder().decode(WidgetStyle.self, from: $0) }
    }

    // MARK: الشكل الافتراضي
    // يأخذه كل نوع لم يخصّصه المستخدم، ويُعدَّل من الإعدادات
    private static let defaultKey = "widget.defaultStyle"

    static func defaultStyle(in defaults: UserDefaults = AppGroup.defaults) -> WidgetStyle {
        defaults.data(forKey: defaultKey).flatMap { try? JSONDecoder().decode(WidgetStyle.self, from: $0) } ?? .default
    }

    static func saveDefaultStyle(_ style: WidgetStyle, in defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(try? JSONEncoder().encode(style), forKey: defaultKey)
    }

    /// `nil` يرجع النوع لشكله الافتراضي
    static func save(_ style: WidgetStyle?, for kindIDs: [String], in defaults: UserDefaults = AppGroup.defaults) {
        var all = stored(in: defaults)
        let data = style.flatMap { try? JSONEncoder().encode($0) }
        for id in kindIDs {
            all[id] = data
        }
        defaults.set(all, forKey: key)
    }

    /// شكل الودجت: النمط الذي اختاره المستخدم لهذه النسخة إن وُجد، وإلا شكل النوع
    static func style(for kindID: String, savedStyleID: UUID?, in defaults: UserDefaults = AppGroup.defaults) -> WidgetStyle {
        if let savedStyleID, let saved = savedStyles(in: defaults).first(where: { $0.id == savedStyleID }) {
            return saved.style
        }
        return style(for: kindID, in: defaults)
    }

    // MARK: الأنماط المحفوظة
    private static let savedKey = "widget.savedStyles"

    static func savedStyles(in defaults: UserDefaults = AppGroup.defaults) -> [SavedStyle] {
        guard let data = defaults.data(forKey: savedKey) else { return [] }
        return (try? JSONDecoder().decode([SavedStyle].self, from: data)) ?? []
    }

    static func saveSavedStyles(_ styles: [SavedStyle], in defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(try? JSONEncoder().encode(styles), forKey: savedKey)
    }

    private static func stored(in defaults: UserDefaults) -> [String: Data] {
        defaults.dictionary(forKey: key) as? [String: Data] ?? [:]
    }
}
