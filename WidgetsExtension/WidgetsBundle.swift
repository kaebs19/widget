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
