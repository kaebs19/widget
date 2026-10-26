//
//  WatchLocator.swift
//  WidgetsWatch
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import CoreLocation
import Observation

/// يحدد موقع الساعة مرة واحدة لأوقات الصلاة، ويرسله للآيفون حتى يتطابق الجهازان
@MainActor
@Observable
final class WatchLocator: NSObject, CLLocationManagerDelegate {
    private(set) var isLocating = false
    private(set) var isDenied = false
    private(set) var location = PrayerLocation.saved

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        isDenied = [.denied, .restricted].contains(manager.authorizationStatus)
    }

    /// موقع جديد وصل من الآيفون
    func refresh() { location = PrayerLocation.saved }

    func locate() {
        isLocating = true
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if isDenied {
            isLocating = false
        } else {
            manager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            isDenied = [.denied, .restricted].contains(status)
            guard isLocating else { return }
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.requestLocation()
            } else if isDenied {
                isLocating = false
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let found = locations.last else { return }
        Task { @MainActor in await save(found) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in isLocating = false }
    }

    private func save(_ found: CLLocation) async {
        let placemark = try? await CLGeocoder().reverseGeocodeLocation(found, preferredLocale: Locale(identifier: "ar")).first
        let saved = PrayerLocation(latitude: found.coordinate.latitude, longitude: found.coordinate.longitude,
                                   city: placemark?.locality ?? placemark?.administrativeArea ?? "موقعي")
        if let data = try? JSONEncoder().encode(saved) {
            WatchSession.shared.set(data, forKey: WatchKeys.location)
        }
        location = saved
        isLocating = false
    }
}
