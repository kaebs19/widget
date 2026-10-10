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
    case prayer, religious, calendar, health, occasions, finance, sports

    var id: String { rawValue }

    /// الأقسام المتاحة على هذا الجهاز: الماك ليس فيه تطبيق الصحة
    static var available: [WidgetCategory] {
        #if targetEnvironment(macCatalyst)
        allCases.filter { $0 != .health }
        #else
        allCases
        #endif
    }

    var title: String {
        switch self {
        case .prayer:    "الصلاة"
        case .religious: "ديني"
        case .calendar:  "تقويم"
        case .health:    "الصحة"
        case .occasions: "مناسبات"
        case .finance:   "المال والأعمال"
        case .sports:    "رياضة"
        }
    }

    var icon: AppIcon {
        switch self {
        case .prayer:    .asset(.iconMosque)
        case .religious: .asset(.iconCategoryReligious)
        case .calendar:  .asset(.iconCategoryCalendar)
        case .health:    .system("heart")
        case .occasions: .asset(.iconCategoryOccasions)
        case .finance:   .system("banknote")
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
    case salary, citizenAccount, hafiz, retirement, socialSecurity, studentBonus, rehabilitation, paydays
    case obligations, budget
    case healthSteps, healthActivity, healthDashboard, healthSleep
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
        case .salary:       "موعد الراتب"
        case .citizenAccount: "حساب المواطن"
        case .hafiz:        "حافز"
        case .retirement:   "التقاعد"
        case .socialSecurity: "الضمان المطور"
        case .studentBonus: "مكافأة الجامعة"
        case .rehabilitation: "التأهيل الشامل"
        case .paydays:      "مواعيد الصرف"
        case .obligations:  "التزاماتي"
        case .budget:       "مصروف اليوم"
        case .healthSteps:  "الخطوات"
        case .healthActivity: "حلقات النشاط"
        case .healthDashboard: "صحتي اليوم"
        case .healthSleep:  "النوم"
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
        case .salary:       "كم يوم باقي على الراتب، حكومي أو خاص"
        case .citizenAccount: "موعد إيداع دعم حساب المواطن"
        case .hafiz:        "موعد صرف حافز"
        case .retirement:   "موعد صرف معاش التقاعد"
        case .socialSecurity: "موعد إيداع الضمان الاجتماعي المطور"
        case .studentBonus: "موعد صرف مكافأة طلاب الجامعات"
        case .rehabilitation: "موعد صرف إعانة التأهيل الشامل"
        case .paydays:      "الراتب وحساب المواطن وحافز والتقاعد في مكان واحد"
        case .obligations:  "الإيجار والأقساط والفواتير بمواعيدها"
        case .budget:       "كم تصرف كل يوم حتى الراتب، وسجّل مصروفك من الشاشة"
        case .healthSteps:  "خطوات اليوم مقابل هدفك، وأسبوعك في رسم"
        case .healthActivity: "السعرات والتمرين والخطوات في ثلاث حلقات"
        case .healthDashboard: "الخطوات والمسافة والسعرات والتمرين والطوابق والنوم"
        case .healthSleep:  "ساعات نوم الليلة مقابل هدفك"
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
        case .salary, .citizenAccount, .hafiz, .retirement, .socialSecurity, .studentBonus,
             .rehabilitation, .paydays, .obligations, .budget: .finance
        case .healthSteps, .healthActivity, .healthDashboard, .healthSleep: .health
        case .nextMatch:                               .sports
        }
    }

    /// الحجم اللي يظهر في المعرض
    var previewSize: WidgetSize {
        switch self {
        case .istighfar, .ramadan, .eid, .foundingDay, .tearOff, .dualDate,
             .prayerRing, .prayerBar, .citizenAccount, .hafiz, .retirement,
             .socialSecurity, .studentBonus, .rehabilitation,
             .healthSteps, .healthActivity, .healthSleep: .small
        case .dailyVerse:                              .large
        default:                                       .medium
        }
    }

    /// يعرض اسم يوم أو شهر يمكن كتابته بالخط العربي
    /// الدفعة التي يعرضها ودجت المال (nil لـ «مواعيد الصرف» الذي يعرضها كلها)
    var payday: Payday? {
        Payday.allCases.first { $0.widgetKind == self }
    }

    var supportsCalligraphy: Bool {
        self == .hijriDate || self == .dayName
    }

    /// كل الأحجام المتاحة لهذا الودجت
    var supportedSizes: [WidgetSize] {
        switch self {
        case .istighfar, .ramadan, .eid, .foundingDay, .tearOff, .dualDate,
             .prayerRing, .prayerBar: [.small]
        case .gregorianMonth, .hijriMonth, .prayerDay: [.medium]
        case .prayerList:                              [.medium, .large]
        case .dailyVerse:                              [.medium, .large]
        case .paydays:                                 [.medium, .large]
        case .obligations:                             [.small, .medium, .large]
        case .healthDashboard:                         [.medium, .large]
        case .healthSleep:                             [.small]
        case .specialOccasion:                         [.medium]
        default:                                       [.small, .medium]
        }
    }
}
