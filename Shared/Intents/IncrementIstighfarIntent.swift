//
//  IncrementIstighfarIntent.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents
import WidgetKit

/// زر «+» في Widget الاستغفار. يشتغل من الشاشة الرئيسية بدون فتح التطبيق،
/// وبعد التنفيذ يعيد النظام رسم الـ Widget بالعدد الجديد.
nonisolated struct IncrementIstighfarIntent: AppIntent {
    static let title: LocalizedStringResource = "استغفار"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        IstighfarCounter.increment()
        // لو الضغط من داخل التطبيق، نحدّث نسخة الشاشة الرئيسية كذلك
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.istighfar.rawValue)
        return .result()
    }
}
