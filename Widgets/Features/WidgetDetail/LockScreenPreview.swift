//
//  LockScreenPreview.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - معاينة شاشة القفل
// نفس عروض الـ Widget بلون واحد فوق خلفية داكنة، كما يرسمها النظام تقريباً
struct LockScreenPreview: View {
    let kind: WidgetKind
    let style: WidgetStyle
    var tasbeeh: TasbeehDhikr = .istighfar

    var body: some View {
        let families = kind.lockScreenFamilies
        if !families.isEmpty {
            SettingsSection("شاشة القفل") {
                VStack(spacing: 14) {
                    if families.contains(.accessoryInline) {
                        widget(.accessoryInline)
                            .frame(width: 260, height: 22)
                    }
                    HStack(spacing: 14) {
                        if families.contains(.accessoryCircular) {
                            widget(.accessoryCircular)
                                .frame(width: 72, height: 72)
                                .background(.white.opacity(0.14), in: Circle())
                        }
                        if families.contains(.accessoryRectangular) {
                            widget(.accessoryRectangular)
                                .frame(width: 172, height: 76)
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(
                    LinearGradient(colors: [Color(white: 0.22), Color(white: 0.08)], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .environment(\.colorScheme, .dark)
                Text("اضغط مطولاً على شاشة القفل ثم «تخصيص» لإضافتها.")
                    .font(AppFont.ui(12))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func widget(_ family: WidgetFamily) -> some View {
        switch kind {
        case .istighfar:
            TasbeehLockView(dhikr: tasbeeh, date: .now, family: family, style: style)
                .environment(\.layoutDirection, .rightToLeft)
        case .specialOccasion:
            let occasion = OccasionStore.all().min { $0.nextDate() < $1.nextDate() }
            let target = occasion?.nextDate() ?? .now.addingTimeInterval(13 * 86_400)
            let days = DateHelper.gregorian.dateComponents([.day], from: DateHelper.gregorian.startOfDay(for: .now),
                                                           to: DateHelper.gregorian.startOfDay(for: target)).day ?? 0
            LockCountdownView(countdown: LockCountdown(title: occasion?.name ?? "عيد ميلاد سارة",
                                                       symbol: occasion?.type.symbol ?? "birthday.cake",
                                                       days: days, detail: DateHelper.weekdayDayMonth(target)),
                              family: family, style: style)
                .environment(\.layoutDirection, .rightToLeft)
        default:
            LockScreenWidgetView(kind: kind, date: .now, family: family, style: style)
        }
    }
}
