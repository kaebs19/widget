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
    case prayer, religious, calendar, health, occasions, finance, weather, sports

    var id: String { rawValue }

    /// الأقسام التي تظهر في التطبيق. الماك ليس فيه تطبيق الصحة.
    /// الرياضة مخفية حتى يتوفر مصدر بيانات للمباريات (كودها باقٍ في MatchWidget)
    static var available: [WidgetCategory] {
        #if targetEnvironment(macCatalyst)
        allCases.filter { $0 != .health && $0 != .sports }
        #else
        allCases.filter { $0 != .sports }
        #endif
    }

    var title: String {
        switch self {
        case .prayer:    L10n.text("الصلاة")
        case .religious: L10n.text("ديني")
        case .calendar:  L10n.text("تقويم")
        case .health:    L10n.text("الصحة")
        case .occasions: L10n.text("مناسبات")
        case .finance:   L10n.text("المال والأعمال")
        case .weather: L10n.text("الطقس")
        case .sports:    L10n.text("رياضة")
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
        case .weather: .system("cloud.sun.fill")
        case .sports:    .asset(.iconCategorySports)
        }
    }
}

// MARK: - الأحجام
enum WidgetSize: String {
    case small, medium, large

    var title: String {
        switch self {
        case .small:  L10n.text("صغير")
        case .medium: L10n.text("متوسط")
        case .large:  L10n.text("كبير")
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
    case morningDhikr, eveningDhikr, dailyVerse, istighfar, quranGoal
    case dailyOverview, subscriptions
    case ramadan, eid, nationalDay, foundingDay, specialOccasion
    case salary, citizenAccount, hafiz, retirement, socialSecurity, studentBonus, rehabilitation, paydays
    case obligations, budget
    case healthSteps, healthActivity, healthDashboard, healthSleep
    case healthWeekly, healthStreak, healthSleepWeek, healthWater, healthWorkouts
    case weather
    case nextMatch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .prayerRing:   L10n.text("الصلاة القادمة")
        case .prayerBar:    L10n.text("العد التنازلي للصلاة")
        case .prayerDay:    L10n.text("أوقات اليوم")
        case .prayerList:   L10n.text("جدول الصلوات")
        case .hijriDate:    L10n.text("التاريخ الهجري")
        case .dayName:      L10n.text("اسم اليوم")
        case .tearOff:      L10n.text("ورقة التقويم")
        case .dualDate:     L10n.text("التاريخان")
        case .gregorianMonth: L10n.text("الشهر الميلادي")
        case .hijriMonth:   L10n.text("الشهر الهجري")
        case .dailyOverview: L10n.text("يومي")
        case .subscriptions: L10n.text("اشتراكاتي")
        case .quranGoal: L10n.text("ورد القرآن")
        case .eveningDhikr: L10n.text("ذكر المساء")
        case .morningDhikr: L10n.text("ذكر الصباح")
        case .dailyVerse:   L10n.text("آية اليوم")
        case .istighfar:    L10n.text("عداد الذكر")
        case .ramadan:      L10n.text("عداد رمضان")
        case .eid:          L10n.text("عداد العيد")
        case .nationalDay:  L10n.text("اليوم الوطني")
        case .foundingDay:  L10n.text("يوم التأسيس")
        case .specialOccasion: L10n.text("مناسبة خاصة")
        case .salary:       L10n.text("موعد الراتب")
        case .citizenAccount: L10n.text("حساب المواطن")
        case .hafiz:        L10n.text("حافز")
        case .retirement:   L10n.text("التقاعد")
        case .socialSecurity: L10n.text("الضمان المطور")
        case .studentBonus: L10n.text("مكافأة الجامعة")
        case .rehabilitation: L10n.text("التأهيل الشامل")
        case .paydays:      L10n.text("مواعيد الصرف")
        case .obligations:  L10n.text("التزاماتي")
        case .budget:       L10n.text("مصروف اليوم")
        case .healthWeekly: L10n.text("أسبوعي الصحي")
        case .healthStreak: L10n.text("استمراريتي")
        case .healthSleepWeek: L10n.text("نومي هذا الأسبوع")
        case .healthWater: L10n.text("ماء اليوم")
        case .healthWorkouts: L10n.text("تماريني")
        case .healthSteps:  L10n.text("الخطوات")
        case .healthActivity: L10n.text("حلقات النشاط")
        case .healthDashboard: L10n.text("صحتي اليوم")
        case .healthSleep:  L10n.text("النوم")
        case .weather: L10n.text("الطقس والتوقعات")
        case .nextMatch:    L10n.text("المباراة القادمة")
        }
    }

    var subtitle: String {
        switch self {
        case .prayerRing:   L10n.text("الصلاة القادمة والوقت المتبقي في حلقة")
        case .prayerBar:    L10n.text("الصلاة القادمة مع شريط الوقت")
        case .prayerDay:    L10n.text("الصلوات الخمس في صف واحد")
        case .prayerList:   L10n.text("قائمة الصلوات مع العد التنازلي")
        case .hijriDate:    L10n.text("التاريخ بتقويم أم القرى مع الميلادي")
        case .dayName:      L10n.text("اسم اليوم بخط عربي فخم")
        case .tearOff:      L10n.text("اسم اليوم ورقمه مثل ورقة التقويم")
        case .dualDate:     L10n.text("اليوم بالتاريخين الهجري والميلادي")
        case .gregorianMonth: L10n.text("أيام الشهر الميلادي واليوم مميّز")
        case .hijriMonth:   L10n.text("أيام الشهر الهجري بتقويم أم القرى")
        case .dailyOverview: L10n.text("التاريخ والصلاة القادمة وأقرب مناسبة في مكان واحد")
        case .subscriptions: L10n.text("تجديد الاشتراكات وتكلفتها الشهرية بالريال السعودي")
        case .quranGoal: L10n.text("هدفك اليومي من صفحات القرآن، وسجّل إنجازك من الشاشة")
        case .eveningDhikr: L10n.text("أذكار المساء من حصن المسلم")
        case .morningDhikr: L10n.text("أذكار الصباح من حصن المسلم")
        case .dailyVerse:   L10n.text("آية جديدة كل يوم بالرسم العثماني")
        case .istighfar:    L10n.text("استغفار وتسبيح وتهليل وصلاة على النبي ﷺ، تعدّها بالضغط من الشاشة")
        case .ramadan:      L10n.text("كم يوم باقي على رمضان")
        case .eid:          L10n.text("كم يوم باقي على أقرب عيد")
        case .nationalDay:  L10n.text("العد التنازلي لـ ٢٣ سبتمبر")
        case .foundingDay:  L10n.text("العد التنازلي لـ ٢٢ فبراير")
        case .specialOccasion: L10n.text("اختر اسم مناسبتك وتاريخها من «تعديل الودجت»")
        case .salary:       L10n.text("كم يوم باقي على الراتب، حكومي أو خاص")
        case .citizenAccount: L10n.text("موعد إيداع دعم حساب المواطن")
        case .hafiz:        L10n.text("موعد صرف حافز")
        case .retirement:   L10n.text("موعد صرف معاش التقاعد")
        case .socialSecurity: L10n.text("موعد إيداع الضمان الاجتماعي المطور")
        case .studentBonus: L10n.text("موعد صرف مكافأة طلاب الجامعات")
        case .rehabilitation: L10n.text("موعد صرف إعانة التأهيل الشامل")
        case .paydays:      L10n.text("الراتب وحساب المواطن وحافز والتقاعد في مكان واحد")
        case .obligations:  L10n.text("الإيجار والأقساط والفواتير بمواعيدها")
        case .budget:       L10n.text("ميزانية تقديرية حتى الراتب وتسجيل مصروف يدوي؛ دون ربط بنكي أو دفع فعلي")
        case .healthWeekly: L10n.text("متوسط الخطوات ودقائق التمرين وأيام تحقيق الهدف في آخر ٧ أيام")
        case .healthStreak: L10n.text("سلسلة تحقيق هدف الخطوات وتقويم إنجاز آخر ٣٠ يومًا")
        case .healthSleepWeek: L10n.text("نوم كل ليلة ومتوسط آخر ٧ أيام حسب القراءات المتاحة")
        case .healthWater: L10n.text("هدف ماء تحدده بنفسك، وسجّل كوبًا أو تراجع عنه من الشاشة")
        case .healthWorkouts: L10n.text("آخر تمرين ومدته وإجمالي التمارين الأسبوعية من تطبيق الصحة")
        case .healthSteps:  L10n.text("خطوات اليوم مقابل هدفك، وأسبوعك في رسم")
        case .healthActivity: L10n.text("السعرات والتمرين والخطوات في ثلاث حلقات")
        case .healthDashboard: L10n.text("الخطوات والمسافة والسعرات والتمرين والطوابق والنوم")
        case .healthSleep:  L10n.text("ساعات نوم الليلة مقابل هدفك")
        case .weather: L10n.text("الطقس الآن وتوقعات الساعات والأيام لمدينتك")
        case .nextMatch:    L10n.text("موعد مباراة فريقك القادمة")
        }
    }

    var category: WidgetCategory {
        switch self {
        case .prayerRing, .prayerBar, .prayerDay, .prayerList: .prayer
        case .dailyOverview, .hijriDate, .dayName, .tearOff, .dualDate,
             .gregorianMonth, .hijriMonth:             .calendar
        case .morningDhikr, .eveningDhikr, .quranGoal, .dailyVerse, .istighfar:   .religious
        case .ramadan, .eid, .nationalDay, .foundingDay, .specialOccasion: .occasions
        case .salary, .citizenAccount, .hafiz, .retirement, .socialSecurity, .studentBonus,
             .rehabilitation, .paydays, .subscriptions, .obligations, .budget: .finance
        case .healthSteps, .healthActivity, .healthDashboard, .healthSleep,
             .healthWeekly, .healthStreak, .healthSleepWeek, .healthWater, .healthWorkouts: .health
        case .weather: .weather
        case .nextMatch:                               .sports
        }
    }

    /// الحجم اللي يظهر في المعرض
    var previewSize: WidgetSize {
        switch self {
        case .istighfar, .ramadan, .eid, .foundingDay, .tearOff, .dualDate,
             .prayerRing, .prayerBar, .citizenAccount, .hafiz, .retirement,
             .socialSecurity, .studentBonus, .rehabilitation,
             .healthSteps, .healthActivity, .healthSleep, .healthWater: .small
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
        case .weather: [.small, .medium, .large]
        case .istighfar, .ramadan, .eid, .foundingDay, .tearOff, .dualDate,
             .prayerRing, .prayerBar: [.small]
        case .gregorianMonth, .hijriMonth, .prayerDay: [.medium]
        case .prayerList:                              [.medium, .large]
        case .dailyVerse:                              [.medium, .large]
        case .paydays:                                 [.medium, .large]
        case .obligations:                             [.small, .medium, .large]
        case .healthDashboard:                         [.medium, .large]
        case .healthSleep:                             [.small]
        case .healthWeekly, .healthStreak, .healthSleepWeek, .healthWorkouts: [.medium]
        case .specialOccasion, .dailyOverview, .subscriptions: [.medium]
        case .quranGoal: [.small, .medium]
        default:                                       [.small, .medium]
        }
    }
}
