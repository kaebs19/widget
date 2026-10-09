//
//  WidgetKind.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - الأقسام
// CaseIterable يعطيك allCases تلقائياً، فتبني شريط الأقسام بحلقة بدون ما تكتب كل قسم يدوياً.
enum WidgetCategory: String, CaseIterable, Identifiable {
    case prayer, religious, calendar, occasions, sports

    var id: String { rawValue }

    var title: String {
        switch self {
        case .prayer:    "الصلاة"
        case .religious: "ديني"
        case .calendar:  "تقويم"
        case .occasions: "مناسبات"
        case .sports:    "رياضة"
        }
    }

    var icon: AppIcon {
        switch self {
        case .prayer:    .asset(.iconMosque)
        case .religious: .asset(.iconCategoryReligious)
        case .calendar:  .asset(.iconCategoryCalendar)
        case .occasions: .asset(.iconCategoryOccasions)
        case .sports:    .asset(.iconCategorySports)
        }
    }
}

// MARK: - الأحجام
enum WidgetSize: String {
    case small, medium, large

    var title: String {
        switch self {
        case .small:  "صغير"
        case .medium: "متوسط"
        case .large:  "كبير"
        }
    }

    /// مقاسات iPhone Pro Max، ونستخدم النسبة بس عشان المعاينة تتأقلم مع أي شاشة
    var size: CGSize {
        switch self {
        case .small:  CGSize(width: 170, height: 170)
        case .medium: CGSize(width: 364, height: 170)
        case .large:  CGSize(width: 364, height: 382)
        }
    }

    var aspectRatio: CGFloat { size.width / size.height }
}

// MARK: - نوع الودجت
// كل نوع يعرف قسمه وحجمه واسمه. لما تضيف ودجت جديد، تضيف case هنا وبس.
enum WidgetKind: String, CaseIterable, Identifiable {
    case prayerRing, prayerBar, prayerDay, prayerList
    case hijriDate, dayName
    case tearOff, dualDate, gregorianMonth, hijriMonth
    case morningDhikr, dailyVerse, istighfar
    case ramadan, eid, nationalDay, foundingDay, specialOccasion
    case nextMatch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .prayerRing:   "الصلاة القادمة"
        case .prayerBar:    "العد التنازلي للصلاة"
        case .prayerDay:    "أوقات اليوم"
        case .prayerList:   "جدول الصلوات"
        case .hijriDate:    "التاريخ الهجري"
        case .dayName:      "اسم اليوم"
        case .tearOff:      "ورقة التقويم"
        case .dualDate:     "التاريخان"
        case .gregorianMonth: "الشهر الميلادي"
        case .hijriMonth:   "الشهر الهجري"
        case .morningDhikr: "ذكر الصباح"
        case .dailyVerse:   "آية اليوم"
        case .istighfar:    "عداد الذكر"
        case .ramadan:      "عداد رمضان"
        case .eid:          "عداد العيد"
        case .nationalDay:  "اليوم الوطني"
        case .foundingDay:  "يوم التأسيس"
        case .specialOccasion: "مناسبة خاصة"
        case .nextMatch:    "المباراة القادمة"
        }
    }

    var subtitle: String {
        switch self {
        case .prayerRing:   "الصلاة القادمة والوقت المتبقي في حلقة"
        case .prayerBar:    "الصلاة القادمة مع شريط الوقت"
        case .prayerDay:    "الصلوات الخمس في صف واحد"
        case .prayerList:   "قائمة الصلوات مع العد التنازلي"
        case .hijriDate:    "التاريخ بتقويم أم القرى مع الميلادي"
        case .dayName:      "اسم اليوم بخط عربي فخم"
        case .tearOff:      "اسم اليوم ورقمه مثل ورقة التقويم"
        case .dualDate:     "اليوم بالتاريخين الهجري والميلادي"
        case .gregorianMonth: "أيام الشهر الميلادي واليوم مميّز"
        case .hijriMonth:   "أيام الشهر الهجري بتقويم أم القرى"
        case .morningDhikr: "أذكار الصباح من حصن المسلم"
        case .dailyVerse:   "آية جديدة كل يوم بالرسم العثماني"
        case .istighfar:    "استغفار وتسبيح وتهليل وصلاة على النبي ﷺ، تعدّها بالضغط من الشاشة"
        case .ramadan:      "كم يوم باقي على رمضان"
        case .eid:          "كم يوم باقي على أقرب عيد"
        case .nationalDay:  "العد التنازلي لـ ٢٣ سبتمبر"
        case .foundingDay:  "العد التنازلي لـ ٢٢ فبراير"
        case .specialOccasion: "اختر اسم مناسبتك وتاريخها من «تعديل الودجت»"
        case .nextMatch:    "موعد مباراة فريقك القادمة"
        }
    }

    var category: WidgetCategory {
        switch self {
        case .prayerRing, .prayerBar, .prayerDay, .prayerList: .prayer
        case .hijriDate, .dayName, .tearOff, .dualDate,
             .gregorianMonth, .hijriMonth:             .calendar
        case .morningDhikr, .dailyVerse, .istighfar:   .religious
        case .ramadan, .eid, .nationalDay, .foundingDay, .specialOccasion: .occasions
        case .nextMatch:                               .sports
        }
    }

    /// الحجم اللي يظهر في المعرض
    var previewSize: WidgetSize {
        switch self {
        case .istighfar, .ramadan, .eid, .foundingDay, .tearOff, .dualDate,
             .prayerRing, .prayerBar: .small
        case .dailyVerse:                              .large
        default:                                       .medium
        }
    }

    /// يعرض اسم يوم أو شهر يمكن كتابته بالخط العربي
    var supportsCalligraphy: Bool {
        self == .hijriDate || self == .dayName
    }

    /// كل الأحجام المتاحة لهذا الودجت
    var supportedSizes: [WidgetSize] {
        switch self {
        case .istighfar, .ramadan, .eid, .foundingDay, .tearOff, .dualDate,
             .prayerRing, .prayerBar: [.small]
        case .gregorianMonth, .hijriMonth, .prayerDay, .prayerList: [.medium]
        case .dailyVerse:                              [.medium, .large]
        case .specialOccasion:                         [.medium]
        default:                                       [.small, .medium]
        }
    }
}
