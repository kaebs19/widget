//
//  LockScreenWidgetView.swift
//  WidgetsExtension
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

extension WidgetKind {
    /// أحجام شاشة القفل لكل نوع (التصاميم ٢٢–٢٥)
    var lockScreenFamilies: [WidgetFamily] {
        switch self {
        case .hijriDate:    [.accessoryRectangular, .accessoryInline]
        case .morningDhikr: [.accessoryRectangular]
        case .ramadan:      [.accessoryCircular]
        default:            []
        }
    }
}

extension WidgetFamily {
    var isLockScreen: Bool {
        switch self {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: true
        default: false
        }
    }
}

// MARK: - شاشة القفل
// النظام يلوّن شاشة القفل بلون واحد، فالتمييز يكون بالوزن والشفافية (.secondary) لا بالألوان.
struct LockScreenWidgetView: View {
    let kind: WidgetKind
    let date: Date
    let family: WidgetFamily

    /// المستطيل يتسع لسطرين قصيرين فقط
    private static let dhikrMaxLetters = 40

    var body: some View {
        content
            .environment(\.layoutDirection, .rightToLeft)
            .containerBackground(for: .widget) {
                if family == .accessoryCircular { AccessoryWidgetBackground() } else { Color.clear }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch (kind, family) {
        case (.hijriDate, .accessoryInline):
            // السطر الواحد يقبل نصاً وأيقونة فقط، وبخط النظام واتجاه لغة الجهاز.
            // نص عادي (لا LocalizedStringKey) حتى لا تُعزل أجزاؤه فينقلب ترتيبها، و\u{200F} يثبّته من اليمين.
            Label("\u{200F}" + DateHelper.hijriDayMonth(date) + " " + DateHelper.hijriYear(date), systemImage: "moon")
        case (.hijriDate, _):
            hijriRectangular
        case (.morningDhikr, _):
            dhikrRectangular
        case (.ramadan, _):
            ramadanCircular
        default:
            EmptyView()
        }
    }

    // التصميم ٢٣
    private var hijriRectangular: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(DateHelper.weekday(date), systemImage: "moon")
                .font(AppFont.uiBold(15))
            Text(DateHelper.hijriDayMonth(date))
                .font(AppFont.uiBold(17))
            Text("\(DateHelper.hijriYear(date)) هـ · \(DateHelper.gregorianDayMonth(date))")
                .font(AppFont.ui(12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // التصميم ٢٤
    @ViewBuilder
    private var dhikrRectangular: some View {
        if let zikr = AzkarLibrary.bundled.rotatingZikr(in: ZikrGroup.morningID, at: date,
                                                         maxLetters: Self.dhikrMaxLetters) {
            VStack(alignment: .leading, spacing: 0) {
                Label("ذكر الصباح", systemImage: "sun.max")
                    .font(AppFont.ui(11))
                    .foregroundStyle(.secondary)
                Text(zikr.text)
                    .font(AppFont.zikr(16))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if let repeatLabel = DhikrWidget.repeatLabel(zikr.repeatCount) {
                    Text(repeatLabel)
                        .font(AppFont.ui(11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // التصميم ٢٢: حلقة تمتلئ كلما قرب رمضان
    private var ramadanCircular: some View {
        Gauge(value: DateHelper.progressUntilHijri(month: 9, day: 1, from: date)) {
            EmptyView()
        } currentValueLabel: {
            VStack(spacing: 0) {
                Image(systemName: "moon.fill")
                    .font(.system(size: 9))
                Text(DateHelper.arabic(DateHelper.daysUntilHijri(month: 9, day: 1, from: date)))
                    .font(AppFont.number(17))
                    .minimumScaleFactor(0.6)
                Text("يوم")
                    .font(AppFont.ui(9))
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}
