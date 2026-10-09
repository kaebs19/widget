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
        HijriDateHomeWidget()
        DayNameHomeWidget()
        YearDotsHomeWidget()
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
        NextMatchHomeWidget()
    }
}
