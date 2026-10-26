import Foundation
import CoreLocation
import WeatherKit

nonisolated struct WeatherLocation: Codable, Equatable, Sendable {
    let latitude: Double
    let longitude: Double
    let city: String
    var timeZoneIdentifier: String = TimeZone.current.identifier
    static let key = "weather.location"
    static var saved: Self? {
        AppGroup.defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(Self.self, from: $0) }
    }
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppGroup.defaults.set(data, forKey: Self.key)
        AppGroup.defaults.removeObject(forKey: WeatherCache.key)
        AppGroup.defaults.set(UUID().uuidString, forKey: WeatherCache.revisionKey)
    }
}

nonisolated struct WeatherSnapshot: Codable, Sendable {
    struct Hour: Codable, Identifiable, Sendable {
        var id: Date { date }
        let date: Date
        let symbol: String
        let temperature: Double
        let rain: Double
    }
    struct Day: Codable, Identifiable, Sendable {
        var id: Date { date }
        let date: Date
        let symbol: String
        let low: Double
        let high: Double
    }
    let location: WeatherLocation
    let fetchedAt: Date
    let observedAt: Date
    let temperature: Double
    let feelsLike: Double
    let symbol: String
    let condition: String
    let humidity: Double
    let wind: Double
    let hours: [Hour]
    let days: [Day]
    let attributionURL: URL

    func isStale(at date: Date) -> Bool { date.timeIntervalSince(fetchedAt) > 2 * 3600 }
    static func sample(at date: Date) -> Self {
        let isDay = (6..<18).contains(Calendar.current.component(.hour, from: date))
        return Self(location: .init(latitude: 24.7136, longitude: 46.6753, city: L10n.text("الرياض")),
             fetchedAt: date, observedAt: date, temperature: 29, feelsLike: 28, symbol: isDay ? "sun.max.fill" : "moon.stars.fill", condition: "clear",
             humidity: 0.24, wind: 12,
             hours: (1...5).map { .init(date: date.addingTimeInterval(Double($0) * 3600), symbol: (6..<18).contains(Calendar.current.component(.hour, from: date.addingTimeInterval(Double($0) * 3600))) ? "sun.max.fill" : "moon.stars.fill", temperature: Double(29 - $0), rain: 0) },
             days: (0...3).map { .init(date: date.addingTimeInterval(Double($0) * 86400), symbol: "sun.max.fill", low: Double(20 + $0), high: Double(31 + $0)) },
             attributionURL: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!)
    }
}

nonisolated enum WeatherCache {
    static let key = "weather.snapshot.v1"
    static let revisionKey = "weather.revision"
    static let unitKey = "weather.fahrenheit"
    static func load(now: Date = .now) -> WeatherSnapshot? {
        guard let data = AppGroup.defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WeatherSnapshot.self, from: data),
              snapshot.location == WeatherLocation.saved,
              now.timeIntervalSince(snapshot.fetchedAt) < 24 * 3600 else { return nil }
        return snapshot
    }
    static func temperature(_ celsius: Double, fahrenheit: Bool) -> String {
        let value = fahrenheit ? celsius * 9 / 5 + 32 : celsius
        return value.formatted(.number.precision(.fractionLength(0)).locale(AppLanguage.current.locale)) + "°"
    }
}

actor WeatherReader {
    static let shared = WeatherReader()
    private var loading = false

    /// Keep the last valid reading on failure. Never associate a response with a newer location.
    func refresh(force: Bool = false) async throws {
        guard !loading, let location = WeatherLocation.saved else { return }
        if !force, let saved = WeatherCache.load(), Date.now.timeIntervalSince(saved.fetchedAt) < 30 * 60 { return }
        loading = true
        defer { loading = false }
        let service = WeatherService.shared
        let weather = try await service.weather(for: CLLocation(latitude: location.latitude, longitude: location.longitude))
        let attribution = try await service.attribution
        let now = Date.now
        let current = weather.currentWeather
        let snapshot = WeatherSnapshot(location: location, fetchedAt: now, observedAt: current.date,
            temperature: current.temperature.converted(to: .celsius).value,
            feelsLike: current.apparentTemperature.converted(to: .celsius).value,
            symbol: current.symbolName, condition: current.condition.rawValue,
            humidity: current.humidity, wind: current.wind.speed.converted(to: .kilometersPerHour).value,
            hours: weather.hourlyForecast.forecast.filter { $0.date > now }.prefix(5).map {
                .init(date: $0.date, symbol: $0.symbolName, temperature: $0.temperature.converted(to: .celsius).value, rain: $0.precipitationChance)
            },
            days: weather.dailyForecast.forecast.prefix(4).map {
                .init(date: $0.date, symbol: $0.symbolName, low: $0.lowTemperature.converted(to: .celsius).value, high: $0.highTemperature.converted(to: .celsius).value)
            }, attributionURL: attribution.legalPageURL)
        guard WeatherLocation.saved == location else { return }
        let data = try JSONEncoder().encode(snapshot)
        AppGroup.defaults.set(data, forKey: WeatherCache.key)
        AppGroup.defaults.set(UUID().uuidString, forKey: WeatherCache.revisionKey)
    }
}
