//
//  Calligraphy.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

/// أسماء الأيام والأشهر بخط الرقعة (SharedAssets/Calligraphy).
enum Calligraphy {
    static func weekday(for date: Date) -> ImageResource {
        weekdays[DateHelper.gregorian.component(.weekday, from: date) - 1]
    }

    /// الشهر الهجري بتقويم أم القرى
    static func hijriMonth(for date: Date) -> ImageResource {
        hijriMonths[DateHelper.hijri.component(.month, from: date) - 1]
    }

    static func gregorianMonth(for date: Date) -> ImageResource {
        gregorianMonths[DateHelper.gregorian.component(.month, from: date) - 1]
    }

    // بترتيب Calendar: الأحد = ١
    private static let weekdays: [ImageResource] = [
        .day1Sunday, .day2Monday, .day3Tuesday, .day4Wednesday, .day5Thursday, .day6Friday, .day7Saturday,
    ]

    private static let hijriMonths: [ImageResource] = [
        .hijri01Muharram, .hijri02Safar, .hijri03RabiAlAwwal, .hijri04RabiAlAkhir,
        .hijri05JumadaAlUla, .hijri06JumadaAlAkhirah, .hijri07Rajab, .hijri08Shaban,
        .hijri09Ramadan, .hijri10Shawwal, .hijri11DhuAlQadah, .hijri12DhuAlHijjah,
    ]

    private static let gregorianMonths: [ImageResource] = [
        .greg01January, .greg02February, .greg03March, .greg04April, .greg05May, .greg06June,
        .greg07July, .greg08August, .greg09September, .greg10October, .greg11November, .greg12December,
    ]
}

extension Image {
    /// كل ملفات الخط بنفس الارتفاع وخط الأساس، فإذا أعطيتها نفس الارتفاع تطلع الحروف بنفس الحجم.
    /// إذا ضاقت المساحة تصغر الصورة بنسبتها بدل ما تنقص.
    func calligraphy(height: CGFloat) -> some View {
        resizable()
            .scaledToFit()
            .frame(height: height)
    }
}
