//
//  WatchCalendarView.swift
//  WidgetsWatch
//
//  Created by Mohammed Saleh on 28/10/2026.
//

import SwiftUI

// MARK: - التقويم على الساعة
// تاريخ اليوم بالهجري والميلادي، وتحته المناسبات القادمة مع ما بقي عليها.
struct WatchCalendarView: View {
    @AppStorage(AppSettings.Key.numerals, store: AppGroup.defaults) private var numerals = Numerals.latin
    @AppStorage(AppSettings.Key.hijriOffset, store: AppGroup.defaults) private var hijriOffset = 0
    @AppStorage(OccasionStore.key, store: AppGroup.defaults) private var occasionsData = Data()

    var body: some View {
        // يتبدّل التاريخ عند منتصف الليل
        TimelineView(.everyMinute) { context in
            ScrollView {
                VStack(spacing: 8) {
                    today(context.date)
                    ForEach(UpcomingOccasions.list(from: context.date).prefix(8)) { occasion in
                        row(occasion)
                    }
                }
                .padding(.horizontal, 6)
            }
        }
        // إعدادات أو مناسبات جديدة من الآيفون تعيد الرسم
        .id("\(numerals.rawValue)|\(hijriOffset)|\(occasionsData.count)")
    }

    private func today(_ date: Date) -> some View {
        VStack(spacing: 0) {
            Text(DateHelper.weekday(date))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(W.accent())
            Text(DateHelper.hijriDay(date))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(W.text)
            Text("\(DateHelper.hijriMonth(date)) \(DateHelper.hijriYear(date))")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(W.text)
            Text(DateHelper.gregorianFull(date))
                .font(.system(size: 11))
                .foregroundStyle(W.muted)
                .padding(.top, 2)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(W.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func row(_ occasion: UpcomingOccasion) -> some View {
        HStack(spacing: 6) {
            Image(systemName: occasion.symbol)
                .font(.system(size: 12))
                .foregroundStyle(W.accent())
                .frame(width: 16)
            Text(occasion.title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(occasion.remaining)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(occasion.days <= 1 ? W.accent() : W.muted)
                .lineLimit(1)
        }
        .foregroundStyle(W.text)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(W.row, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
