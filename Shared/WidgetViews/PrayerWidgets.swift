//
//  PrayerWidgets.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - الصلاة القادمة بحلقة (صغير)
struct PrayerRingWidget: View {
    let date: Date
    @Environment(\.widgetStyle) private var style

    var body: some View {
        if let moment = PrayerSchedule.moment(at: date) {
            ZStack {
                PrayerRing(progress: moment.progress(at: date), lineWidth: 7)
                VStack(spacing: 4) {
                    Image(systemName: moment.next.symbol)
                        .font(.system(size: 20))
                        .foregroundStyle(style.accent)
                        .widgetAccentable()
                    Text(moment.next.title)
                        .font(style.font(.textBold, 18))
                        .foregroundStyle(style.primary)
                    PrayerCountdown(target: moment.nextTime, size: 17)
                }
            }
            .padding(14)
        }
    }
}

// MARK: - الصلاة القادمة بشريط (صغير)
struct PrayerBarWidget: View {
    let date: Date
    @Environment(\.widgetStyle) private var style

    var body: some View {
        if let moment = PrayerSchedule.moment(at: date) {
            VStack(spacing: 8) {
                HStack {
                    Text(moment.today.location.city)
                        .lineLimit(1)
                    Spacer()
                    Text(style.text(PrayerSchedule.format(moment.nextTime)))
                }
                .font(style.font(.label, 10))
                .foregroundStyle(style.secondary)
                Spacer(minLength: 0)
                Image(systemName: moment.next.symbol)
                    .font(.system(size: 26))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
                Text(moment.next.title)
                    .font(style.font(.textBold, 22))
                    .foregroundStyle(style.primary)
                ProgressView(value: moment.progress(at: date))
                    .tint(style.accent)
                    .widgetAccentable()
                PrayerCountdown(target: moment.nextTime, size: 18)
                Spacer(minLength: 0)
            }
            .widgetContent()
        }
    }
}

// MARK: - أوقات اليوم في صف (متوسط)
struct PrayerDayWidget: View {
    let date: Date
    @Environment(\.widgetStyle) private var style
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        if let moment = PrayerSchedule.moment(at: date) {
            let highlighted = PrayerHighlight.upcomingFard(moment)
            VStack(spacing: 8) {
                HStack {
                    Text(style.text("\(DateHelper.weekday(date)) \(DateHelper.hijriDayMonth(date)) \(DateHelper.hijriYear(date))"))
                    Spacer()
                    Label(moment.today.location.city, systemImage: "location.fill")
                        .labelStyle(.titleAndIcon)
                        .lineLimit(1)
                }
                .font(style.font(.labelBold, 11))
                .foregroundStyle(style.secondary)

                HStack(spacing: 4) {
                    ForEach(PrayerName.fard) { prayer in
                        let isOn = prayer == highlighted
                        VStack(spacing: 5) {
                            Image(systemName: prayer.symbol)
                                .font(.system(size: 17))
                                .foregroundStyle(style.accent)
                                .widgetAccentable()
                            Text(style.text(PrayerSchedule.format(moment.today.time(prayer))))
                                .font(style.font(.number, 14))
                                .foregroundStyle(style.primary)
                            Text(prayer.title)
                                .font(style.font(.label, 11))
                                .foregroundStyle(style.secondary)
                        }
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            if isOn {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(style.primary.opacity(renderingMode == .fullColor ? 0.14 : 0.25))
                                    .widgetAccentable()
                            }
                        }
                    }
                }
            }
            .padding(12)
        }
    }
}

// MARK: - قائمة الأوقات وحلقة القادمة (متوسط)
struct PrayerListWidget: View {
    let date: Date
    var size: WidgetSize = .medium
    @Environment(\.widgetStyle) private var style

    var body: some View {
        if size == .large, let moment = PrayerSchedule.moment(at: date) {
            large(moment)
        } else if let moment = PrayerSchedule.moment(at: date) {
            let highlighted = PrayerHighlight.upcomingFard(moment)
            HStack(spacing: 10) {
                VStack(spacing: 1) {
                    ForEach(PrayerName.fard) { prayer in
                        HStack(spacing: 8) {
                            Image(systemName: prayer.symbol)
                                .font(.system(size: 13))
                                .foregroundStyle(style.accent)
                                .widgetAccentable()
                                .frame(width: 18)
                            Text(prayer.title)
                                .font(style.font(.labelBold, 12))
                                .foregroundStyle(style.primary)
                            Spacer()
                            Text(style.text(PrayerSchedule.format(moment.today.time(prayer))))
                                .font(style.font(.number, 13))
                                .foregroundStyle(style.primary)
                        }
                        .padding(.horizontal, 10)
                        .frame(maxHeight: .infinity)
                        .background {
                            if prayer == highlighted {
                                Capsule().fill(style.primary.opacity(0.14)).widgetAccentable()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                ZStack {
                    PrayerRing(progress: moment.progress(at: date), lineWidth: 6)
                    VStack(spacing: 2) {
                        Text(moment.next.title)
                            .font(style.font(.textBold, 17))
                            .foregroundStyle(style.primary)
                        PrayerCountdown(target: moment.nextTime, size: 16)
                        Image(systemName: moment.next.symbol)
                            .font(.system(size: 15))
                            .foregroundStyle(style.accent)
                            .widgetAccentable()
                    }
                }
                .frame(width: 128)
            }
            .padding(12)
        }
    }
}

extension PrayerListWidget {
    // الكبير: التاريخان والمدينة، حلقة كبيرة للقادمة، ثم الأوقات الستة مع الشروق
    fileprivate func large(_ moment: PrayerSchedule.Moment) -> some View {
        let highlighted = moment.next
        return VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DateHelper.weekday(date))
                        .font(style.font(.textBold, 20))
                        .foregroundStyle(style.primary)
                    Text(style.text("\(DateHelper.hijriDayMonth(date)) \(DateHelper.hijriYear(date)) هـ"))
                        .font(style.font(.labelBold, 12))
                        .foregroundStyle(style.accent)
                        .widgetAccentable()
                    Text(style.text(DateHelper.gregorianFull(date)))
                        .font(style.font(.label, 11))
                        .foregroundStyle(style.secondary)
                }
                Spacer()
                ZStack {
                    PrayerRing(progress: moment.progress(at: date), lineWidth: 6)
                    VStack(spacing: 1) {
                        Text(moment.next.title)
                            .font(style.font(.textBold, 15))
                            .foregroundStyle(style.primary)
                        PrayerCountdown(target: moment.nextTime, size: 14)
                    }
                    .padding(10)
                }
                .frame(width: 104, height: 104)
            }

            VStack(spacing: 4) {
                ForEach(PrayerName.allCases) { prayer in
                    let isOn = prayer == highlighted
                    HStack(spacing: 10) {
                        Image(systemName: prayer.symbol)
                            .font(.system(size: 15))
                            .foregroundStyle(style.accent)
                            .widgetAccentable()
                            .frame(width: 22)
                        Text(prayer.title)
                            .font(style.font(isOn ? .labelBold : .label, 14))
                            .foregroundStyle(prayer == .sunrise ? style.secondary : style.primary)
                        Spacer()
                        Text(style.text(PrayerSchedule.format(moment.today.time(prayer))))
                            .font(style.font(.number, 15))
                            .foregroundStyle(style.primary)
                    }
                    .padding(.horizontal, 12)
                    .frame(maxHeight: .infinity)
                    .background {
                        if isOn {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(style.primary.opacity(0.12))
                                .widgetAccentable()
                        }
                    }
                }
            }

            Label(moment.today.location.city, systemImage: "location.fill")
                .font(style.font(.label, 10))
                .foregroundStyle(style.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .widgetContent(padding: 16)
    }
}

// MARK: - أجزاء مشتركة
enum PrayerHighlight {
    /// الصلاة المفروضة القادمة: إذا كان القادم الشروق نميّز الظهر
    static func upcomingFard(_ moment: PrayerSchedule.Moment) -> PrayerName {
        moment.next == .sunrise ? .dhuhr : moment.next
    }
}

/// عدّ تنازلي يتحدّث كل ثانية بدون تحديث الودجت
struct PrayerCountdown: View {
    let target: Date
    let size: CGFloat
    @Environment(\.widgetStyle) private var style

    var body: some View {
        Text(target, style: .timer)
            .font(style.font(.number, size))
            .foregroundStyle(style.primary)
            .multilineTextAlignment(.center)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .environment(\.locale, Locale(identifier: style.numerals == .arabic ? "ar@numbers=arab" : "en"))
    }
}

/// حلقة تمتلئ بين الصلاتين، تبدأ من الأعلى
struct PrayerRing: View {
    let progress: Double
    var lineWidth: CGFloat = 6
    @Environment(\.widgetStyle) private var style

    var body: some View {
        ZStack {
            Circle()
                .stroke(style.primary.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(progress, 0.02))
                .stroke(style.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()
        }
        .padding(lineWidth / 2)
        // الاتجاه العربي يعكس الدوران فتبدأ الحلقة من الأسفل؛ نثبّتها من الأعلى
        .environment(\.layoutDirection, .leftToRight)
    }
}
