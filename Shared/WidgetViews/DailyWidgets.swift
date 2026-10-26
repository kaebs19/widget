import AppIntents
import SwiftUI
import WidgetKit

struct DailyOverviewWidget: View {
    let date: Date
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeader(icon: .system("sun.max"), title: "يومي", trailing: DateHelper.weekday(date))
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.text(DateHelper.hijriDayMonth(date)))
                        .font(style.font(.textBold, 21))
                        .foregroundStyle(style.primary)
                    Text(style.text(DateHelper.gregorianDayMonth(date)))
                        .font(style.font(.label, 12))
                        .foregroundStyle(style.secondary)
                }
                Spacer(minLength: 0)
                if let prayer = PrayerSchedule.moment(at: date) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prayer.next.title + " · " + style.text(PrayerSchedule.format(prayer.nextTime)))
                            .font(style.font(.labelBold, 14))
                        Text(prayer.nextTime, style: .timer)
                            .font(style.font(.number, 18))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .environment(\.locale, Locale(identifier: style.numerals == .arabic ? "ar@numbers=arab" : "en"))
                    }
                    .foregroundStyle(style.accent)
                } else {
                    Text("تعذر حساب الصلاة").font(style.font(.label, 12))
                }
            }
            Spacer(minLength: 0)
            if let occasion = OccasionStore.upcoming(from: date).first {
                let days = DateHelper.gregorian.dateComponents([.day], from: DateHelper.gregorian.startOfDay(for: date),
                                                              to: occasion.nextDate(from: date)).day ?? 0
                Text(occasion.name + " · " + (days == 0 ? "اليوم" : "بعد \(style.number(days)) يوم"))
                    .font(style.font(.label, 12))
                    .foregroundStyle(style.secondary)
                    .lineLimit(1)
            } else {
                Text("أضف مناسباتك من التطبيق")
                    .font(style.font(.label, 12))
                    .foregroundStyle(style.secondary)
            }
        }
        .widgetContent()
    }
}

struct SubscriptionsWidget: View {
    let date: Date
    @Environment(\.widgetStyle) private var style

    var body: some View {
        let items = SubscriptionStore.upcoming(from: date)
        VStack(alignment: .leading, spacing: 7) {
            WidgetHeader(icon: .system("creditcard"), title: "اشتراكاتي",
                         trailing: style.text(SubscriptionStore.amountLabel(items.reduce(0) { $0 + $1.monthlyAmount })) + " / شهر")
            if items.isEmpty {
                Spacer(minLength: 0)
                Text("أضف اشتراكاتك من التطبيق")
                    .font(style.font(.label, 14))
                    .foregroundStyle(style.secondary)
                Spacer(minLength: 0)
            } else {
                ForEach(items.prefix(3)) { item in
                    HStack {
                        Text(item.name).lineLimit(1)
                        Spacer(minLength: 4)
                        Text(style.text(DateHelper.gregorianDayMonth(item.nextRenewal(from: date))))
                            .foregroundStyle(style.secondary)
                        Text(style.text(SubscriptionStore.amountLabel(item.amount)))
                            .foregroundStyle(style.accent)
                    }
                    .font(style.font(.label, 12))
                }
                Spacer(minLength: 0)
            }
        }
        .foregroundStyle(style.primary)
        .widgetContent()
    }
}

struct QuranGoalWidget: View {
    let date: Date
    @AppStorage private var storedPages: Int
    @AppStorage("quranGoal.target", store: AppGroup.defaults) private var target = 5

    init(date: Date) {
        self.date = date
        _storedPages = AppStorage(wrappedValue: 0, "quranGoal.pages." + TasbeehCounter.dayID(for: date), store: AppGroup.defaults)
    }
    @Environment(\.widgetStyle) private var style

    var body: some View {
        let pages = storedPages
        let target = max(1, target)
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeader(icon: .system("book.closed"), title: "ورد القرآن")
            Text("\(style.number(pages)) / \(style.number(target)) صفحة")
                .font(style.font(.labelBold, 17))
                .foregroundStyle(style.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            ProgressView(value: Double(min(pages, target)), total: Double(target))
                .tint(style.accent)
            Spacer(minLength: 0)
            Button(intent: AddQuranPageIntent()) {
                Label(pages >= target ? "زدت خيرًا · صفحة" : "قرأت صفحة", systemImage: "plus")
                    .font(style.font(.labelBold, 12))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .foregroundStyle(style.accent)
            .background(style.accent.opacity(0.12), in: Capsule())
        }
        .widgetContent()
    }
}
