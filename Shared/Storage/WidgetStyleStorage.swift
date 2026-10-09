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

    static func style(for kindID: String, in defaults: UserDefaults = AppGroup.defaults) -> WidgetStyle {
        guard let data = stored(in: defaults)[kindID],
              let style = try? JSONDecoder().decode(WidgetStyle.self, from: data) else { return .default }
        return style
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

    private static func stored(in defaults: UserDefaults) -> [String: Data] {
        defaults.dictionary(forKey: key) as? [String: Data] ?? [:]
    }
}
