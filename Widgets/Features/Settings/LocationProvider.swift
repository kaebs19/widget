//
//  LocationProvider.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import CoreLocation
import Observation
import WidgetKit

/// يطلب موقع المستخدم مرة واحدة لحساب أوقات الصلاة، ويحفظه في المساحة المشتركة للـ Widget.
/// لا يتتبع الموقع باستمرار: المستخدم يحدّثه متى أراد.
@MainActor
@Observable
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private(set) var isLocating = false
    private(set) var errorMessage: String?
    private(set) var location = PrayerLocation.saved
    private(set) var status: CLAuthorizationStatus

    private let manager = CLLocationManager()

    override init() {
        status = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var isDenied: Bool { status == .denied || status == .restricted }

    func locate() {
        errorMessage = nil
        isLocating = true
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if isDenied {
            isLocating = false
            errorMessage = "الوصول للموقع مقفل. فعّله من إعدادات الجهاز."
        } else {
            manager.requestLocation()
        }
    }

    // MARK: CLLocationManagerDelegate
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.status = status
            guard isLocating else { return }
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.requestLocation()
            } else if isDenied {
                isLocating = false
                errorMessage = "بدون الموقع نحسب الأوقات لمكة المكرمة."
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let found = locations.last else { return }
        Task { @MainActor in await save(found) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isLocating = false
            errorMessage = "تعذّر تحديد الموقع، حاول مرة ثانية."
        }
    }

    private func save(_ found: CLLocation) async {
        let placemark = try? await CLGeocoder().reverseGeocodeLocation(found, preferredLocale: Locale(identifier: "ar")).first
        let city = placemark?.locality ?? placemark?.administrativeArea ?? "موقعي"
        let saved = PrayerLocation(latitude: found.coordinate.latitude, longitude: found.coordinate.longitude, city: city)
        saved.save()
        location = saved
        isLocating = false
        PrayerWidgets.reload()
    }
}

enum PrayerWidgets {
    /// ودجات الصلاة تعيد الحساب بالموقع أو الطريقة الجديدة
    static func reload() {
        for kind in WidgetKind.allCases where kind.category == .prayer {
            WidgetCenter.shared.reloadTimelines(ofKind: kind.rawValue)
        }
    }
}
