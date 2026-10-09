//
//  IncrementIstighfarIntent.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents
import WidgetKit

/// زر «+» في ودجت العدّاد. يشتغل من الشاشة الرئيسية بدون فتح التطبيق،
/// وبعد التنفيذ يعيد النظام رسم الـ Widget بالعدد الجديد.
nonisolated struct IncrementIstighfarIntent: AppIntent {
    static let title: LocalizedStringResource = "عدّ الذكر"
    static let isDiscoverable = false

    @Parameter(title: "الذكر", default: .istighfar)
    var dhikr: TasbeehDhikr

    init() {}

    init(dhikr: TasbeehDhikr) {
        self.dhikr = dhikr
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        TasbeehCounter.increment(dhikr)
        // لو الضغط من داخل التطبيق، نحدّث نسخة الشاشة الرئيسية كذلك
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.istighfar.rawValue)
        return .result()
    }
}
