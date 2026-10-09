//
//  QiblaView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import CoreLocation
import SwiftUI

// MARK: - اتجاه القبلة
// المكتبة تحسب زاوية القبلة من الشمال للموقع المحفوظ، والبوصلة تدير السهم حسب اتجاه الجهاز
struct QiblaView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var compass = CompassHeading()
    private let location = PrayerLocation.current
    private var qibla: Double { PrayerSchedule.qiblaDirection(location: location) }

    /// زاوية السهم على الشاشة: القبلة ناقص اتجاه الجهاز
    private var arrowAngle: Double { qibla - (compass.heading ?? 0) }
    private var isAligned: Bool {
        guard compass.heading != nil else { return false }
        let diff = abs((arrowAngle.truncatingRemainder(dividingBy: 360) + 540).truncatingRemainder(dividingBy: 360) - 180)
        return diff < 5
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    Circle()
                        .strokeBorder(isAligned ? Theme.gold : Theme.border, lineWidth: isAligned ? 4 : 2)
                        .background(Circle().fill(Theme.cardTop.opacity(0.6)))
                    // علامات الاتجاهات تدور مع الجهاز، والنص نفسه يبقى قائماً
                    ForEach(Array(["ش", "ق", "ج", "غ"].enumerated()), id: \.offset) { index, letter in
                        let angle = (Double(index) * 90 - (compass.heading ?? 0)) * .pi / 180
                        Text(letter)
                            .font(AppFont.uiBold(16))
                            .foregroundStyle(index == 0 ? Theme.gold : Theme.textSecondary)
                            .offset(x: sin(angle) * 125, y: -cos(angle) * 125)
                    }
                    // السهم من المركز نحو القبلة
                    VStack(spacing: 0) {
                        Image(systemName: "arrowtriangle.up.fill")
                            .font(.system(size: 34))
                        Capsule().frame(width: 6, height: 70)
                        Spacer()
                    }
                    .foregroundStyle(Theme.gold)
                    .frame(height: 220)
                    .rotationEffect(.degrees(arrowAngle))
                    AppIconView(icon: .asset(.iconMosque), size: 26)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(14)
                        .background(Theme.background, in: Circle())
                }
                .frame(width: 300, height: 300)
                .environment(\.layoutDirection, .leftToRight)
                .animation(.easeOut(duration: 0.2), value: compass.heading)

                VStack(spacing: 6) {
                    Text("\(DateHelper.arabic(Int(qibla.rounded())))° من الشمال")
                        .font(AppFont.uiBold(22))
                        .foregroundStyle(Theme.textPrimary)
                    Text(location.city)
                        .font(AppFont.ui(14))
                        .foregroundStyle(Theme.textSecondary)
                    Text(compass.heading == nil
                         ? "البوصلة غير متاحة على هذا الجهاز، وجّه أعلى الجوال للشمال ثم اتبع الزاوية."
                         : (isAligned ? "أنت متجه للقبلة" : "أدر الجوال حتى يشير السهم للأعلى"))
                        .font(AppFont.ui(14))
                        .foregroundStyle(isAligned ? Theme.gold : Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .sensoryFeedback(.success, trigger: isAligned) { _, new in new }
                }
                Spacer()
                Text("ضع الجوال مسطّحاً وبعيداً عن المعادن للحصول على اتجاه دقيق.")
                    .font(AppFont.ui(12))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("اتجاه القبلة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }
                }
            }
            .onAppear { compass.start() }
            .onDisappear { compass.stop() }
        }
        .tint(Theme.gold)
    }
}

/// اتجاه الجهاز من البوصلة (الشمال الحقيقي)
@MainActor
@Observable
final class CompassHeading: NSObject, CLLocationManagerDelegate {
    private(set) var heading: Double?
    private let manager = CLLocationManager()

    func start() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.delegate = self
        manager.headingFilter = 1
        manager.startUpdatingHeading()
    }

    func stop() { manager.stopUpdatingHeading() }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in heading = value }
    }
}
