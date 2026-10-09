//
//  Tasbeeh.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents

// MARK: - أذكار العدّاد
// ودجت العدّاد يعرض أحد هذه الأذكار، ويختاره المستخدم لكل نسخة من «تعديل الودجت».
nonisolated enum TasbeehDhikr: String, AppEnum, CaseIterable, Identifiable, Sendable {
    case istighfar, subhanAllah, tahlilOnce, tahlilHundred, salawat

    var id: Self { self }

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "الذكر"
    static let caseDisplayRepresentations: [TasbeehDhikr: DisplayRepresentation] = [
        .istighfar: "أستغفر الله · ١٠٠ مرة",
        .subhanAllah: "سبحان الله · ٣٣ مرة",
        .tahlilOnce: "لا إله إلا الله وحده… · مرة واحدة",
        .tahlilHundred: "لا إله إلا الله وحده… · ١٠٠ مرة",
        .salawat: "الصلاة على النبي ﷺ · عدد مفتوح",
    ]

    /// النص كما يظهر في الودجت
    var text: String {
        switch self {
        case .istighfar:     "أستغفر الله"
        case .subhanAllah:   "سبحان الله"
        case .tahlilOnce, .tahlilHundred:
            "لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير"
        case .salawat:       "الصلاة على النبي ﷺ"
        }
    }

    /// العنوان الصغير أعلى الودجت
    var title: String {
        switch self {
        case .istighfar:   "الاستغفار"
        case .subhanAllah: "التسبيح"
        case .tahlilOnce, .tahlilHundred: "التهليل"
        case .salawat:     "الصلاة على النبي"
        }
    }

    /// العدد المطلوب في اليوم؛ nil يعني عدداً مفتوحاً بلا هدف
    var goal: Int? {
        switch self {
        case .istighfar, .tahlilHundred: 100
        case .subhanAllah: 33
        case .tahlilOnce:  1
        case .salawat:     nil
        }
    }

    /// النص طويل فيحتاج أسطراً وخطاً أصغر
    var isLong: Bool { text.count > 30 }

    /// مفاتيح العدد في المساحة المشتركة. الاستغفار يحتفظ بمفاتيحه القديمة حتى لا يضيع عدد اليوم.
    var countKey: String { self == .istighfar ? "istighfar.count" : "tasbeeh.\(rawValue).count" }
    var dayKey: String { self == .istighfar ? "istighfar.day" : "tasbeeh.\(rawValue).day" }
}
