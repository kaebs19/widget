//
//  OnboardingPreviews.swift
//  Widgets
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import CoreLocation
import SwiftUI

// MARK: - معاينة الموقع
/// رادار ينبض أثناء التحديد، ثم تظهر أوقات الصلاة واحداً تلو الآخر
struct LocationPreview: View {
    enum State { case idle, detecting, found }

    let state: State
    let location: PrayerLocation?

    var body: some View {
        GeometryReader { proxy in
            let radarY = (proxy.size.height - 72) / 2 + 2
            ZStack {
                ForEach(1...3, id: \.self) { ring in
                    Circle()
                        .stroke(OB.line, lineWidth: 1)
                        .frame(width: CGFloat(ring) * 48, height: CGFloat(ring) * 48)
                }
                if state != .idle {
                    TimelineView(.animation) { context in
                        let time = context.date.timeIntervalSinceReferenceDate
                        ZStack {
                            ForEach(0..<3, id: \.self) { index in
                                let phase = (time + Double(index) * 0.6).truncatingRemainder(dividingBy: 1.8) / 1.8
                                Circle()
                                    .stroke(OB.accent, lineWidth: 2)
                                    .frame(width: 140, height: 140)
                                    .scaleEffect(0.3 + phase * 1.2)
                                    .opacity((1 - phase) * (state == .found ? 0.2 : 0.55))
                            }
                        }
                    }
                    .transition(.opacity)
                }
                Image(systemName: "mappin")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(state == .idle ? OB.muted : OB.onAccent)
                    .frame(width: 44, height: 44)
                    .background(state == .idle ? OB.card2 : OB.accent, in: Circle())
                    .phaseAnimator([1.0, 1.12, 1.0], trigger: state == .found) { view, scale in
                        view.scaleEffect(scale)
                    } animation: { scale in
                        scale > 1 ? OB.pop(0.5) : OB.enter(0.5)
                    }
            }
            .position(x: proxy.size.width / 2, y: radarY)

            prayerStrip
                .frame(height: 54)
                .padding(.horizontal, 12)
                .position(x: proxy.size.width / 2, y: proxy.size.height - 39)
        }
        .animation(OB.enter(0.4), value: state)
    }

    private var prayerStrip: some View {
        let day = state == .found ? PrayerSchedule.day(for: .now, location: location ?? .current) : nil
        return HStack(spacing: 4) {
            ForEach(Array(PrayerName.fard.enumerated()), id: \.element) { index, prayer in
                VStack(spacing: 1) {
                    ZStack {
                        Text("--:--")
                            .foregroundStyle(OB.dim)
                            .opacity(day == nil ? 1 : 0)
                        Text(day.map { PrayerSchedule.format($0.time(prayer)) } ?? "")
                            .foregroundStyle(OB.text)
                            .opacity(day == nil ? 0 : 1)
                            .offset(y: day == nil ? 8 : 0)
                    }
                    .font(OB.font(14, .bold))
                    .animation(OB.enter(0.45).delay(Double(index) * 0.12), value: day == nil)
                    Text(L10n.text(prayer.title))
                        .font(OB.font(11))
                        .foregroundStyle(OB.muted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(index == 0 ? OB.card2 : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(4)
        .background(OB.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - معاينة الإشعارات
/// كل تنبيه مفعّل يظهر كإشعار، وتذكير «قبل الصلاة» ينزل من الأعلى ويدفع البقية
struct NotificationPreview: View {
    let adhan: Bool
    let prePrayer: Bool
    let afterAdhkar: Bool

    var body: some View {
        let moment = PrayerSchedule.moment(at: .now)
        let city = PrayerLocation.current.city
        let upcoming = moment.map { $0.next == .sunrise ? PrayerName.dhuhr : $0.next } ?? .fajr
        let upcomingTime = moment.map { PrayerSchedule.format($0.today.time(upcoming)) } ?? ""
        let isha = moment.map { PrayerSchedule.format($0.today.time(.isha)) } ?? ""
        VStack(spacing: 8) {
            if prePrayer {
                banner(title: String(format: L10n.text("%@ بعد %@ دقائق"), L10n.text(upcoming.title), DateHelper.arabic(10)),
                       body: String(format: L10n.text("%@ عند %@ · %@"), L10n.text(upcoming.title), upcomingTime, city), when: L10n.text("الآن"))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            if adhan {
                banner(title: L10n.text("حان وقت صلاة العشاء"), body: "\(city) · \(isha)",
                       when: String(format: L10n.text("%@ د"), DateHelper.arabic(10)))
                    .transition(.opacity)
            }
            if afterAdhkar {
                banner(title: L10n.text("أذكار بعد الصلاة"), body: L10n.text("لا تنسَ أذكارك بعد الصلاة"),
                       when: String(format: L10n.text("%@ د"), DateHelper.arabic(5)))
                    .transition(.opacity)
            }
            if !(adhan || prePrayer || afterAdhkar) {
                Text(L10n.text("لا تنبيهات"))
                    .font(OB.font(14))
                    .foregroundStyle(OB.dim)
                    .frame(maxHeight: .infinity)
                    .transition(.opacity)
            }
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
        .animation(OB.move(0.5), value: [adhan, prePrayer, afterAdhkar])
    }

    private func banner(title: String, body: String, when: String) -> some View {
        HStack(spacing: 10) {
            WidgetLogo()
                .frame(width: 20, height: 20)
                .frame(width: 34, height: 34)
                .background(Color(white: 0.086), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title).font(OB.font(13, .bold)).foregroundStyle(OB.text).lineLimit(1)
                    Spacer(minLength: 6)
                    Text(when).font(OB.font(11)).foregroundStyle(OB.muted)
                }
                Text(body).font(OB.font(12)).foregroundStyle(OB.muted).lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 62)
        .background(OB.bannerBg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(OB.bannerLine, lineWidth: 1))
    }
}

// MARK: - معاينة الإعدادات العامة
/// ودجت الصلاة القادمة وودجت التاريخ، وأرقامهما تتبدل مع اختيار شكل الأرقام
struct GeneralPreview: View {
    let numerals: Numerals
    let flash: Bool

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.height - 28, (proxy.size.width - 36) / 2)
            HStack(spacing: 12) {
                ring(side)
                date(side)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(\.locale, Locale(identifier: numerals == .arabic ? "ar@numbers=arab" : "en"))
    }

    private func ring(_ side: CGFloat) -> some View {
        let moment = PrayerSchedule.moment(at: .now)
        let next = moment?.next ?? .fajr
        return ZStack {
            Circle()
                .stroke(OB.ringTrack, lineWidth: side * 0.035)
                .padding(side * 0.12)
            Circle()
                .trim(from: 0, to: moment?.progress(at: .now) ?? 0.64)
                .stroke(OB.accent, style: StrokeStyle(lineWidth: side * 0.035, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(side * 0.12)
                .environment(\.layoutDirection, .leftToRight)
            VStack(spacing: side * 0.015) {
                Image(systemName: next.symbol)
                    .font(.system(size: side * 0.12))
                    .foregroundStyle(OB.accent)
                Text(L10n.text(next.title))
                    .font(OB.font(side * 0.09, .bold))
                    .foregroundStyle(OB.text)
                if let moment {
                    Text(timerInterval: Date.now...moment.nextTime, countsDown: true)
                        .font(OB.font(side * 0.095, .bold))
                        .monospacedDigit()
                        .foregroundStyle(OB.text)
                        .multilineTextAlignment(.center)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
        }
        .frame(width: side, height: side)
        .background(OB.card, in: RoundedRectangle(cornerRadius: side * 0.09, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: side * 0.09, style: .continuous).strokeBorder(OB.line, lineWidth: 1))
    }

    private func date(_ side: CGFloat) -> some View {
        let scale = side / 264
        let now = Date.now
        return VStack(spacing: 2 * scale) {
            Text(DateHelper.weekday(now))
                .font(OB.font(18 * scale, .semibold))
                .foregroundStyle(OB.accent)
            Text(DateHelper.hijriDay(now))
                .font(OB.font(84 * scale, .bold))
                .foregroundStyle(OB.text)
            Text("\(DateHelper.hijriMonth(now)) \(DateHelper.hijriYear(now))")
                .font(OB.font(19 * scale))
                .foregroundStyle(OB.text)
            Text(DateHelper.gregorianFull(now))
                .font(OB.font(15 * scale))
                .foregroundStyle(OB.muted)
                .padding(.top, 4 * scale)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(width: side, height: side)
        .background(OB.card, in: RoundedRectangle(cornerRadius: side * 0.09, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: side * 0.09, style: .continuous).strokeBorder(OB.line, lineWidth: 1))
        // الأرقام تنقلب بحركة خفيفة عند تغيير شكلها
        .contentTransition(.numericText())
        .animation(OB.move(0.3), value: numerals)
    }
}

// MARK: - البحث عن مدينة
/// بديل التحديد التلقائي إذا رُفض إذن الموقع أو أراد المستخدم مدينة أخرى
struct CitySearchView: View {
    let onPick: (PrayerLocation) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var results: [PrayerLocation] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            List(results, id: \.self) { result in
                Button {
                    onPick(result)
                    dismiss()
                } label: {
                    Label(result.city, systemImage: "mappin.and.ellipse")
                        .font(AppFont.ui(16))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .overlay {
                if isSearching {
                    ProgressView()
                } else if results.isEmpty {
                    Text(query.isEmpty ? L10n.text("اكتب اسم مدينتك") : L10n.text("لا نتائج"))
                        .font(AppFont.ui(15))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: L10n.text("المدينة"))
            .navigationTitle(L10n.text("اختر المدينة"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("إلغاء"), systemImage: "xmark") { dismiss() }
                }
            }
            .task(id: query) { await search() }
        }
    }

    private func search() async {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2 else { results = []; return }
        try? await Task.sleep(for: .milliseconds(400))
        guard !Task.isCancelled else { return }
        isSearching = true
        defer { isSearching = false }
        let placemarks = (try? await CLGeocoder().geocodeAddressString(text, in: nil, preferredLocale: Locale(identifier: "ar"))) ?? []
        guard !Task.isCancelled else { return }
        results = placemarks.compactMap { placemark in
            guard let coordinate = placemark.location?.coordinate else { return nil }
            let name = [placemark.locality ?? placemark.name, placemark.country].compactMap { $0 }.joined(separator: AppLanguage.current.isRightToLeft ? "، " : ", ")
            return PrayerLocation(latitude: coordinate.latitude, longitude: coordinate.longitude,
                                  city: placemark.locality ?? placemark.name ?? name)
        }
    }
}
