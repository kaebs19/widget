//
//  WidgetPreviewView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - الموزّع
// View واحد يعرض أي ودجت حسب نوعه. نفس هذا الـ View يستخدمه التطبيق للمعاينة،
// والـ Widget Extension للعرض الحقيقي، فما تكتب التصميم مرتين.
struct WidgetPreviewView: View {
    let kind: WidgetKind
    var date: Date = .now
    /// الحجم المعروض؛ إذا لم يُحدَّد نستخدم حجم المعرض
    var size: WidgetSize? = nil
    /// الشكل الذي اختاره المستخدم لهذا النوع
    var style: WidgetStyle = .default
    /// التطبيق يرسم الخلفية هنا، والـ Widget يرسمها عبر containerBackground
    var showsBackground = true
    /// الذكر الذي يعرضه ودجت العدّاد
    var tasbeeh: TasbeehDhikr = .istighfar

    var body: some View {
        content
            .environment(\.widgetStyle, style)
            .environment(\.layoutDirection, .rightToLeft)
            .background {
                if showsBackground {
                    WidgetBackgroundView(background: style.background)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .prayerRing:   PrayerRingWidget(date: date)
        case .prayerBar:    PrayerBarWidget(date: date)
        case .prayerDay:    PrayerDayWidget(date: date)
        case .prayerList:   PrayerListWidget(date: date)
        case .hijriDate:    HijriDateWidget(date: date, size: resolvedSize)
        case .dayName:      DayNameWidget(date: date, size: resolvedSize)
        case .tearOff:      TearOffCalendarWidget(date: date)
        case .dualDate:     DualDateWidget(date: date)
        case .gregorianMonth: MonthCalendarWidget(date: date, isHijri: false)
        case .hijriMonth:   MonthCalendarWidget(date: date, isHijri: true)
        case .morningDhikr:
            let maxLetters = DhikrWidget.maxLetters(for: resolvedSize, style: style)
            if let zikr = AzkarLibrary.bundled.rotatingZikr(in: ZikrGroup.morningID, at: date, maxLetters: maxLetters) {
                DhikrWidget(zikr: zikr, showsInfo: resolvedSize != .small)
            }
        case .dailyVerse:
            let maxLetters = VerseWidget.maxLetters(for: resolvedSize, style: style)
            if let verse = QuranLibrary.bundled.verseOfDay(at: date, maxLetters: maxLetters) {
                VerseWidget(verse: verse, size: resolvedSize)
            }
        case .istighfar:    IstighfarWidget(dhikr: tasbeeh, date: date)
        case .ramadan:
            let next = DateHelper.nextHijri(month: 9, day: 1, from: date)
            CountdownWidget(title: "رمضان \(DateHelper.hijriYear(next))", icon: .asset(.iconCrescentLantern),
                            days: DateHelper.daysUntilHijri(month: 9, day: 1, from: date),
                            progress: DateHelper.progressUntilHijri(month: 9, day: 1, from: date),
                            footnote: "≈ \(DateHelper.gregorianFull(next))")
        case .eid:
            let eid = DateHelper.nextEid(from: date)
            CountdownWidget(title: "\(DateHelper.hijriMonth(eid.date)) \(DateHelper.hijriYear(eid.date))",
                            icon: .asset(.iconEidStar), days: eid.days, name: eid.name,
                            footnote: "≈ \(DateHelper.gregorianFull(eid.date))")
        case .nationalDay:  NationalDayWidget(date: date, size: resolvedSize)
        case .foundingDay:
            let next = DateHelper.nextGregorian(month: 2, day: 22, from: date)
            let anniversary = DateHelper.gregorian.component(.year, from: next) - 1727
            CountdownWidget(title: DateHelper.gregorianDayMonth(next), icon: .asset(.iconFoundingFlag),
                            days: DateHelper.daysUntilGregorian(month: 2, day: 22, from: date),
                            name: "يوم التأسيس",
                            footnote: "الذكرى \(DateHelper.arabic(anniversary)) · \(DateHelper.arabic(1727))م",
                            footnoteIsAccent: true)
        case .specialOccasion:
            // مثال للمعرض؛ في الشاشة الرئيسية يختار المستخدم الاسم والتاريخ
            // أقرب مناسبة حفظها المستخدم، وإلا مثال
            if let next = OccasionStore.all().min(by: { $0.nextDate(from: date) < $1.nextDate(from: date) }) {
                SpecialOccasionWidget(name: next.name, occasionDate: next.date, repeatsYearly: next.repeatsYearly,
                                      date: date, type: next.type)
            } else {
                SpecialOccasionWidget(name: "عيد ميلاد سارة",
                                      occasionDate: date.addingTimeInterval((13 * 24 + 6) * 3600),
                                      repeatsYearly: false, date: date, type: .birthday)
            }
        case .nextMatch:    MatchWidget()
        }
    }

    private var resolvedSize: WidgetSize { size ?? kind.previewSize }
}
