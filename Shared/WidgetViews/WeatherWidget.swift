import SwiftUI

struct WeatherWidget: View {
    let date: Date
    let size: WidgetSize
    let allowsSample: Bool
    @AppStorage(WeatherCache.revisionKey, store: AppGroup.defaults) private var revision = ""
    @AppStorage(WeatherCache.unitKey, store: AppGroup.defaults) private var fahrenheit = false
    @Environment(\.widgetStyle) private var style

    var body: some View {
        let _ = revision
        let saved = WeatherCache.load(now: date)
        let sample = saved == nil && allowsSample
        Group {
            if let data = saved ?? (sample ? .sample(at: date) : nil) {
                if size == .medium { mediumForecast(data, sample: sample) }
                else { forecast(data, sample: sample) }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "cloud.sun.fill").font(.system(size: 32)).foregroundStyle(style.accent)
                    Text(L10n.text(WeatherLocation.saved == nil ? "اختر موقع الطقس" : "تعذّر تحديث الطقس"))
                        .font(style.font(.labelBold, 15))
                    Text(L10n.text("افتح التطبيق لتحديث الطقس"))
                        .font(style.font(.label, 11)).foregroundStyle(style.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(style.primary)
        .padding(size == .small ? 13 : 16)
        .environment(\.locale, AppLanguage.current.locale)
        .environment(\.layoutDirection, AppLanguage.current.isRightToLeft ? .rightToLeft : .leftToRight)
    }

    private func temperature(_ value: Double) -> String { WeatherCache.temperature(value, fahrenheit: fahrenheit) }

    private func footer(_ data: WeatherSnapshot, sample: Bool) -> some View {
        HStack(spacing: 4) {
            if sample { Text(L10n.text("بيانات تجريبية للمعاينة")) }
            else {
                Text(L10n.text(data.isStale(at: date) ? "بيانات قديمة" : "آخر تحديث"))
                Text(data.fetchedAt, style: .time)
                Spacer(minLength: 2)
                Link(destination: data.attributionURL) { Label("Weather", systemImage: "apple.logo") }
            }
        }.font(style.font(.label, 8)).foregroundStyle(style.secondary).lineLimit(1)
    }

    private func mediumForecast(_ data: WeatherSnapshot, sample: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(data.location.city, systemImage: "location.fill")
                    .font(style.font(.labelBold, 12)).lineLimit(1)
                Spacer()
                Text(fahrenheit ? "°F" : "°C").font(style.font(.label, 10))
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(temperature(data.temperature)).font(style.font(.labelBold, 34))
                        Image(systemName: data.symbol).symbolRenderingMode(.multicolor).font(.system(size: 22))
                    }
                    Text(L10n.text("weather.condition." + data.condition))
                        .font(style.font(.label, 10)).lineLimit(1)
                    if let today = data.days.first {
                        Text("↑ \(temperature(today.high))  ↓ \(temperature(today.low))")
                            .font(style.font(.label, 10)).foregroundStyle(style.secondary)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                HStack(spacing: 6) {
                    ForEach(data.hours.prefix(3)) { hour in
                        VStack(spacing: 6) {
                            Text(hour.date, format: .dateTime.hour()).font(style.font(.label, 9))
                            Image(systemName: hour.symbol).symbolRenderingMode(.multicolor).font(.system(size: 17))
                            Text(temperature(hour.temperature)).font(style.font(.labelBold, 12))
                        }.frame(maxWidth: .infinity)
                    }
                }.frame(maxWidth: .infinity)
            }.frame(maxHeight: .infinity)
            footer(data, sample: sample)
        }
        .environment(\.timeZone, TimeZone(identifier: data.location.timeZoneIdentifier) ?? .current)
    }

    private func forecast(_ data: WeatherSnapshot, sample: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(data.location.city, systemImage: "location.fill")
                    .font(style.font(.labelBold, 12)).lineLimit(1)
                Spacer(minLength: 4)
                Text(fahrenheit ? "°F" : "°C").font(style.font(.label, 10)).foregroundStyle(style.secondary)
            }
            HStack(alignment: .center) {
                Text(temperature(data.temperature))
                    .font(style.font(.labelBold, size == .small ? 38 : 36))
                    .minimumScaleFactor(0.7).lineLimit(1)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 3) {
                    Image(systemName: data.symbol).symbolRenderingMode(.multicolor)
                        .font(.system(size: size == .small ? 27 : 30))
                    if size != .small {
                        Text(L10n.text("weather.condition." + data.condition)).font(style.font(.label, 11)).lineLimit(1)
                    }
                }
            }
            if size == .small {
                Text(L10n.text("weather.condition." + data.condition)).font(style.font(.label, 10)).lineLimit(1)
            }
            if let today = data.days.first {
                HStack(spacing: 8) {
                    Label(temperature(today.high), systemImage: "arrow.up")
                    Label(temperature(today.low), systemImage: "arrow.down")
                }.font(style.font(.label, 11)).foregroundStyle(style.secondary)
            }
            if size != .small {
                Divider().overlay(style.secondary.opacity(0.15))
                HStack(spacing: 4) {
                    ForEach(data.hours) { hour in
                        VStack(spacing: 4) {
                            Text(hour.date, format: .dateTime.hour()).font(style.font(.label, 9))
                            Image(systemName: hour.symbol).symbolRenderingMode(.multicolor).font(.system(size: 16))
                            Text(temperature(hour.temperature)).font(style.font(.labelBold, 11))
                        }.frame(maxWidth: .infinity)
                    }
                }
            }
            if size == .large {
                HStack {
                    Label(data.humidity.formatted(.percent.precision(.fractionLength(0))), systemImage: "humidity.fill")
                    Spacer()
                    Text("\(L10n.text("الرياح")) \(Int(data.wind.rounded())) \(L10n.text("كم/س"))")
                }.font(style.font(.label, 11)).foregroundStyle(style.secondary)
                Divider()
                VStack(spacing: 8) {
                    ForEach(data.days) { day in
                        HStack {
                            Text(day.date, format: .dateTime.weekday(.wide)).frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: day.symbol).symbolRenderingMode(.multicolor)
                            Spacer()
                            Text("\(temperature(day.low))  —  \(temperature(day.high))")
                        }
                        .font(style.font(.label, 14))
                        .frame(maxHeight: .infinity)
                    }
                }.frame(maxHeight: .infinity)

            }
            if size != .large { Spacer(minLength: 0) }
            footer(data, sample: sample)
        }
        .environment(\.timeZone, TimeZone(identifier: data.location.timeZoneIdentifier) ?? .current)
    }
}
