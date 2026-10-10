//
//  WidgetsBundle.swift
//  WidgetsExtension
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

@main
struct WidgetsBundle: WidgetBundle {
    init() {
        AppFontFamily.validateRegistration()
    }

    var body: some Widget {
        coreWidgets
        healthWidgets
    }

    /// الصحة غير متاحة على الماك، فلا تظهر ودجاتها في قائمة إضافة الودجات هناك
    @WidgetBundleBuilder
    private var healthWidgets: some Widget {
        #if !targetEnvironment(macCatalyst)
        HealthStepsHomeWidget()
        HealthActivityHomeWidget()
        HealthDashboardHomeWidget()
        HealthSleepHomeWidget()
        #endif
    }

    @WidgetBundleBuilder
    private var coreWidgets: some Widget {
        PrayerRingHomeWidget()
        PrayerBarHomeWidget()
        PrayerDayHomeWidget()
        PrayerListHomeWidget()
        HijriDateHomeWidget()
        DayNameHomeWidget()
        TearOffHomeWidget()
        DualDateHomeWidget()
        GregorianMonthHomeWidget()
        HijriMonthHomeWidget()
        MorningDhikrHomeWidget()
        DailyVerseHomeWidget()
        IstighfarHomeWidget()
        RamadanHomeWidget()
        EidHomeWidget()
        NationalDayHomeWidget()
        FoundingDayHomeWidget()
        SpecialOccasionHomeWidget()
        SalaryHomeWidget()
        CitizenAccountHomeWidget()
        HafizHomeWidget()
        RetirementHomeWidget()
        SocialSecurityHomeWidget()
        StudentBonusHomeWidget()
        RehabilitationHomeWidget()
        PaydaysHomeWidget()
        BudgetHomeWidget()
        ObligationsHomeWidget()
        NextMatchHomeWidget()
    }
}
