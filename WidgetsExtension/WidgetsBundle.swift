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
        MorningDhikrHomeWidget()
        DailyVerseHomeWidget()
        IstighfarHomeWidget()
        RamadanHomeWidget()
        NationalDayHomeWidget()
        FoundingDayHomeWidget()
        SpecialOccasionHomeWidget()
        NextMatchHomeWidget()
    }
}
