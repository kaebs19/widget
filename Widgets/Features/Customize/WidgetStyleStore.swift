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
    private var styles: [WidgetKind: WidgetStyle] = [:]

    init() {
        for kind in WidgetKind.allCases {
            styles[kind] = WidgetStyleStorage.style(for: kind.rawValue)
        }
    }

    func style(for kind: WidgetKind) -> WidgetStyle {
        styles[kind] ?? .default
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
}
