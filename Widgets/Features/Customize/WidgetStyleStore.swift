//
//  WidgetStyleStore.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Observation
import SwiftUI
import WidgetKit

/// أشكال الودجات داخل التطبيق: المعرض يعرضها، وشاشة التخصيص تحفظ فيها.
@Observable
final class WidgetStyleStore {
    /// الأنواع التي خصّصها المستخدم فقط؛ البقية تأخذ `defaultStyle`
    private var styles: [WidgetKind: WidgetStyle] = [:]
    /// الشكل الافتراضي لكل ودجت لم يُخصَّص، يُعدَّل من الإعدادات
    private(set) var defaultStyle: WidgetStyle = .default
    /// أنماط بأسماء يختارها المستخدم لكل نسخة ودجت من «تعديل الودجت»
    private(set) var savedStyles: [SavedStyle] = []

    init() {
        for kind in WidgetKind.allCases {
            styles[kind] = WidgetStyleStorage.customStyle(for: kind.rawValue)
        }
        defaultStyle = WidgetStyleStorage.defaultStyle()
        savedStyles = WidgetStyleStorage.savedStyles()
        // عند التشغيل ما فيه تعديلات معلّقة، فأي صورة لا يستخدمها شكل محفوظ صارت زائدة
        let photoIDs = styles.values.compactMap(\.background.photoID) + savedStyles.compactMap(\.style.background.photoID)
            + [defaultStyle.background.photoID].compactMap { $0 }
        BackgroundImageStore.removeUnused(keeping: Set(photoIDs))
    }

    func style(for kind: WidgetKind) -> WidgetStyle {
        styles[kind] ?? defaultStyle
    }

    /// يغيّر الشكل الافتراضي؛ يظهر في كل ودجت لم يخصّصه المستخدم
    func saveDefault(_ style: WidgetStyle) {
        defaultStyle = style
        WidgetStyleStorage.saveDefaultStyle(style)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// يمسح تخصيص كل الأنواع، فتأخذ كلها الشكل الافتراضي
    func resetAllToDefault() {
        styles.removeAll()
        WidgetStyleStorage.save(nil, for: WidgetKind.allCases.map(\.rawValue))
        WidgetCenter.shared.reloadAllTimelines()
    }

    func save(_ style: WidgetStyle, for kinds: [WidgetKind]) {
        for kind in kinds {
            styles[kind] = style
        }
        WidgetStyleStorage.save(style, for: kinds.map(\.rawValue))
        // الودجات في الشاشة الرئيسية تتحدث فوراً بالشكل الجديد
        for kind in kinds {
            WidgetCenter.shared.reloadTimelines(ofKind: kind.rawValue)
        }
    }

    // MARK: الأنماط المحفوظة
    func addSavedStyle(named name: String, style: WidgetStyle) {
        savedStyles.append(SavedStyle(name: name, style: style))
        persistSavedStyles()
    }

    func updateSavedStyle(_ id: SavedStyle.ID, with style: WidgetStyle) {
        guard let index = savedStyles.firstIndex(where: { $0.id == id }) else { return }
        savedStyles[index].style = style
        persistSavedStyles()
    }

    func deleteSavedStyle(_ id: SavedStyle.ID) {
        savedStyles.removeAll { $0.id == id }
        persistSavedStyles()
    }

    /// أي نسخة ودجت تستخدم النمط تتحدث فوراً؛ والمحذوف ترجع نسخه لشكل نوعها
    private func persistSavedStyles() {
        WidgetStyleStorage.saveSavedStyles(savedStyles)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
