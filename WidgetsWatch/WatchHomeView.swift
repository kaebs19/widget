//
//  WatchHomeView.swift
//  WidgetsWatch
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import SwiftUI

// MARK: - الرئيسية على الساعة
// حلقة الصلاة القادمة بالعد التنازلي، وتحتها أوقات اليوم. تُحسب على الساعة نفسها بإعدادات الآيفون.
struct WatchHomeView: View {
    @AppStorage(AppSettings.Key.numerals, store: AppGroup.defaults) private var numerals = Numerals.latin
    @AppStorage(WatchKeys.location, store: AppGroup.defaults) private var locationData = Data()
    @AppStorage(PrayerSchedule.Key.method, store: AppGroup.defaults) private var method = PrayerMethod.ummAlQura
    @AppStorage(AppSettings.Key.hijriOffset, store: AppGroup.defaults) private var hijriOffset = 0
    @State private var appeared = false

    var body: some View {
        // يُعاد الحساب كل دقيقة، والعد التنازلي يتحرك وحده
        TimelineView(.everyMinute) { context in
            let moment = PrayerSchedule.moment(at: context.date)
            ScrollView {
                VStack(spacing: 8) {
                    ring(moment, now: context.date)
                        .rise(appeared, delay: 0.2)
                    Text("\(PrayerLocation.current.city) · \(DateHelper.hijriDayMonth(context.date))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(W.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let moment {
                        ForEach(Array(PrayerName.fard.enumerated()), id: \.element) { index, prayer in
                            row(prayer, time: moment.today.time(prayer), isNext: prayer == moment.next)
                                .rise(appeared, delay: 0.5 + Double(index) * 0.12)
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
        }
        // المفاتيح أعلاه تعيد الرسم عند وصول إعدادات جديدة من الآيفون
        .id("\(numerals.rawValue)|\(locationData.count)|\(method.rawValue)|\(hijriOffset)")
        .onAppear { appeared = true }
    }

    private func ring(_ moment: PrayerSchedule.Moment?, now: Date) -> some View {
        let next = moment?.next ?? .fajr
        let side: CGFloat = 138
        return ZStack {
            Circle()
                .stroke(W.ringTrack, lineWidth: side * 0.035)
                .padding(side * 0.12)
            Circle()
                .trim(from: 0, to: moment?.progress(at: now) ?? 0)
                .stroke(W.accent(), style: StrokeStyle(lineWidth: side * 0.035, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(side * 0.12)
                .environment(\.layoutDirection, .leftToRight)
            VStack(spacing: 2) {
                Image(systemName: next.symbol)
                    .font(.system(size: side * 0.12))
                    .foregroundStyle(W.accent())
                Text(next.title)
                    .font(.system(size: side * 0.1, weight: .bold))
                    .foregroundStyle(W.text)
                if let moment {
                    Text(timerInterval: now...moment.nextTime, countsDown: true)
                        .font(.system(size: side * 0.1, weight: .bold).monospacedDigit())
                        .foregroundStyle(W.text)
                        .multilineTextAlignment(.center)
                        .environment(\.layoutDirection, .leftToRight)
                        .environment(\.locale, Locale(identifier: numerals == .arabic ? "ar@numbers=arab" : "en"))
                }
            }
        }
        .frame(width: side, height: side)
        .background(W.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func row(_ prayer: PrayerName, time: Date, isNext: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: prayer.symbol)
                .font(.system(size: 13))
                .foregroundStyle(W.accent())
            Text(prayer.title)
                .font(.system(size: 12, weight: .semibold))
            Spacer()
            Text(PrayerSchedule.format(time))
                .font(.system(size: 12, weight: .bold).monospacedDigit())
        }
        .foregroundStyle(W.text)
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(isNext ? W.accent().opacity(0.18) : W.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private extension View {
    /// دخول الأجزاء صعوداً واحداً تلو الآخر، كما في الرئيسية على الآيفون
    func rise(_ appeared: Bool, delay: Double) -> some View {
        opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)
            .animation(W.enter(0.7).delay(delay), value: appeared)
    }
}
