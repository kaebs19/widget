import Foundation

nonisolated enum AppGroup {
    static let suite = "weather.tests.\(UUID().uuidString)"
    static let defaults = UserDefaults(suiteName: suite)!
}

@main struct WeatherChecks {
    static func main() throws {
        defer { AppGroup.defaults.removePersistentDomain(forName: AppGroup.suite) }
        AppGroup.defaults.set("en", forKey: AppLanguage.preferenceKey)
        precondition(WeatherCache.temperature(0, fahrenheit: true) == "32°")
        precondition(WeatherCache.temperature(-10, fahrenheit: false) == "-10°")
        precondition(WeatherCache.load() == nil)
        let now = Date.now
        let snapshot = WeatherSnapshot.sample(at: now)
        snapshot.location.save()
        let data = try JSONEncoder().encode(snapshot)
        AppGroup.defaults.set(data, forKey: WeatherCache.key)
        precondition(WeatherCache.load(now: now)?.temperature == 29)
        precondition(!snapshot.isStale(at: now))
        precondition(snapshot.isStale(at: now.addingTimeInterval(3 * 3600)))
        precondition(WeatherCache.load(now: now.addingTimeInterval(25 * 3600)) == nil)
        let other = WeatherLocation(latitude: 21.4, longitude: 39.8, city: "Makkah")
        other.save()
        precondition(WeatherCache.load(now: now) == nil)
        // A late response for the old location must never appear under a new city.
        AppGroup.defaults.set(data, forKey: WeatherCache.key)
        precondition(WeatherCache.load(now: now) == nil)
        AppGroup.defaults.set(Data("invalid".utf8), forKey: WeatherCache.key)
        precondition(WeatherCache.load() == nil)
        print("Weather cache, expiry, location isolation, and unit checks passed")
    }
}
