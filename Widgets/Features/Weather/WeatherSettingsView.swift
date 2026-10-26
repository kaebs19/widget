import SwiftUI
import CoreLocation
import WidgetKit

@MainActor @Observable
final class WeatherLocationProvider: NSObject, CLLocationManagerDelegate {
    var isLocating = false
    var error: String?
    private let manager = CLLocationManager()
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    func locate() {
        error = nil
        isLocating = true
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        default: fail("فعّل إذن الموقع من إعدادات الجهاز")
        }
    }
    private func fail(_ message: String) { error = L10n.text(message); isLocating = false }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isLocating else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        case .denied, .restricted: fail("فعّل إذن الموقع من إعدادات الجهاز")
        default: break
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        fail("تعذّر تحديد الموقع، حاول مجددًا")
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { fail("تعذّر تحديد الموقع، حاول مجددًا"); return }
        Task {
            let place = try? await CLGeocoder().reverseGeocodeLocation(location, preferredLocale: AppLanguage.current.locale).first
            WeatherLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude,
                            city: place?.locality ?? place?.administrativeArea ?? L10n.text("موقعي"),
                            timeZoneIdentifier: place?.timeZone?.identifier ?? TimeZone.current.identifier).save()
            isLocating = false
        }
    }
}

struct WeatherSettingsView: View {
    @State private var locationProvider = WeatherLocationProvider()
    @State private var isLoading = false
    @State private var error: String?
    @AppStorage(WeatherCache.revisionKey, store: AppGroup.defaults) private var revision = ""
    @AppStorage(WeatherCache.unitKey, store: AppGroup.defaults) private var fahrenheit = false
    var body: some View {
        SettingsSection(L10n.text("الطقس")) {
            Text(WeatherLocation.saved?.city ?? L10n.text("اختر موقع الطقس"))
                .font(AppFont.uiBold(16))
            Text(L10n.text("موقع الطقس مستقل عن موقع الصلاة. يُحدّث عند طلبك فقط."))
                .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
            Button { locationProvider.locate() } label: {
                Label(L10n.text("استخدام موقعي الحالي"), systemImage: "location.fill")
            }.disabled(locationProvider.isLocating || isLoading)
            Picker(L10n.text("وحدة الحرارة"), selection: $fahrenheit) {
                Text("°C").tag(false)
                Text("°F").tag(true)
            }.pickerStyle(.segmented)
            Button { Task { await refresh(force: true) } } label: {
                Label(L10n.text("تحديث الطقس"), systemImage: "arrow.clockwise")
            }.disabled(isLoading || locationProvider.isLocating || WeatherLocation.saved == nil)
            if isLoading || locationProvider.isLocating { ProgressView() }
            if let message = error ?? locationProvider.error {
                Text(message).font(AppFont.ui(12)).foregroundStyle(.orange)
            }
            if let data = WeatherCache.load() {
                HStack {
                    Text(L10n.text("آخر تحديث"))
                    Text(data.fetchedAt, style: .relative)
                }.font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
                Link(destination: data.attributionURL) { Label("Weather", systemImage: "apple.logo") }
            }
        }
        .task { await refresh(force: false) }
        .onChange(of: locationProvider.isLocating) { old, new in
            if old && !new && locationProvider.error == nil { Task { await refresh(force: true) } }
        }
        .onChange(of: fahrenheit) { WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.weather.rawValue) }
        .id(revision)
    }
    private func refresh(force: Bool) async {
        guard !isLoading, WeatherLocation.saved != nil else { return }
        isLoading = true
        defer { isLoading = false }
        error = nil
        do { try await WeatherReader.shared.refresh(force: force) }
        catch { self.error = L10n.text("تعذّر تحديث الطقس. تحقق من الاتصال وحاول مجددًا.") }
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.weather.rawValue)
    }
}
