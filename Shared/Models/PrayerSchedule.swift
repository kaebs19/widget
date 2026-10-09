//
//  PrayerSchedule.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Adhan
import Foundation

// MARK: - الصلوات
nonisolated enum PrayerName: Int, CaseIterable, Identifiable, Sendable {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    var id: Self { self }

    var title: String {
        switch self {
        case .fajr:    "الفجر"
        case .sunrise: "الشروق"
        case .dhuhr:   "الظهر"
        case .asr:     "العصر"
        case .maghrib: "المغرب"
        case .isha:    "العشاء"
        }
    }

    var symbol: String {
        switch self {
        case .fajr:    "sun.haze"
        case .sunrise: "sunrise"
        case .dhuhr:   "sun.max"
        case .asr:     "sun.min"
        case .maghrib: "sunset"
        case .isha:    "moon.stars"
        }
    }

    /// الصلوات الخمس بدون الشروق، لقوائم الأوقات
    static let fard: [PrayerName] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
}

// MARK: - طرق الحساب
// القائمة من METHODS.md في مكتبة Adhan
nonisolated enum PrayerMethod: String, CaseIterable, Identifiable, Sendable {
    case ummAlQura, muslimWorldLeague, egyptian, karachi, dubai, qatar, kuwait,
         moonsightingCommittee, singapore, turkey, tehran, northAmerica

    var id: Self { self }

    var title: String {
        switch self {
        case .ummAlQura:             "أم القرى"
        case .muslimWorldLeague:     "رابطة العالم الإسلامي"
        case .egyptian:              "الهيئة المصرية"
        case .karachi:               "كراتشي"
        case .dubai:                 "دبي"
        case .qatar:                 "قطر"
        case .kuwait:                "الكويت"
        case .moonsightingCommittee: "لجنة رؤية الهلال"
        case .singapore:             "سنغافورة"
        case .turkey:                "تركيا"
        case .tehran:                "طهران"
        case .northAmerica:          "أمريكا الشمالية"
        }
    }

    fileprivate var adhan: CalculationMethod { CalculationMethod(rawValue: rawValue) ?? .ummAlQura }
}

// MARK: - الموقع المحفوظ
/// الموقع يحدده التطبيق ويحفظه في المساحة المشتركة، والـ Widget يقرأه
nonisolated struct PrayerLocation: Codable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double
    var city: String

    /// قبل أن يحدد المستخدم موقعه نحسب لمكة المكرمة
    static let makkah = PrayerLocation(latitude: 21.4225, longitude: 39.8262, city: "مكة المكرمة")

    private static let key = "prayer.location"

    static var saved: PrayerLocation? {
        AppGroup.defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(PrayerLocation.self, from: $0) }
    }

    static var current: PrayerLocation { saved ?? .makkah }

    func save() {
        AppGroup.defaults.set(try? JSONEncoder().encode(self), forKey: Self.key)
    }
}

// MARK: - أوقات يوم
nonisolated struct PrayerDay: Sendable {
    let date: Date
    let times: [PrayerName: Date]
    let location: PrayerLocation

    func time(_ prayer: PrayerName) -> Date { times[prayer] ?? date }
}

// MARK: - الحساب
nonisolated enum PrayerSchedule {
    enum Key {
        static let method = "prayer.method"
        static let madhab = "prayer.hanafi"
        static func adjustment(_ prayer: PrayerName) -> String { "prayer.adjust.\(prayer.rawValue)" }
    }

    /// دقائق يضيفها المستخدم أو ينقصها لكل صلاة لتطابق أذان مسجده (−٣٠ إلى +٣٠)
    static func adjustment(for prayer: PrayerName) -> Int {
        AppGroup.defaults.integer(forKey: Key.adjustment(prayer))
    }

    static var method: PrayerMethod {
        AppGroup.defaults.string(forKey: Key.method).flatMap(PrayerMethod.init) ?? .ummAlQura
    }

    static var isHanafi: Bool { AppGroup.defaults.bool(forKey: Key.madhab) }

    /// أوقات يوم معيّن في الموقع المحفوظ
    static func day(for date: Date, location: PrayerLocation = .current, calendar: Calendar = .current) -> PrayerDay? {
        var params = method.adhan.params
        params.madhab = isHanafi ? .hanafi : .shafi
        let coordinates = Coordinates(latitude: location.latitude, longitude: location.longitude)
        params.highLatitudeRule = HighLatitudeRule.recommended(for: coordinates)
        // أم القرى: العشاء بعد المغرب بساعتين في رمضان بدل ساعة ونصف (ملاحظة المكتبة)
        let ramadanIsha = method == .ummAlQura
            && DateHelper.hijri.component(.month, from: DateHelper.hijriAdjusted(date)) == 9 ? 30 : 0
        params.adjustments = PrayerAdjustments(
            fajr: adjustment(for: .fajr), sunrise: adjustment(for: .sunrise), dhuhr: adjustment(for: .dhuhr),
            asr: adjustment(for: .asr), maghrib: adjustment(for: .maghrib), isha: adjustment(for: .isha) + ramadanIsha)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let times = PrayerTimes(coordinates: coordinates, date: components, calculationParameters: params) else {
            return nil
        }
        return PrayerDay(date: date, times: [
            .fajr: times.fajr, .sunrise: times.sunrise, .dhuhr: times.dhuhr,
            .asr: times.asr, .maghrib: times.maghrib, .isha: times.isha,
        ], location: location)
    }

    /// اتجاه القبلة بالدرجات من الشمال، للموقع المحفوظ
    static func qiblaDirection(location: PrayerLocation = .current) -> Double {
        Qibla(coordinates: Coordinates(latitude: location.latitude, longitude: location.longitude)).direction
    }

    /// الوقت الحالي: الصلاة الماضية والقادمة (بعد العشاء القادمة فجر الغد)
    struct Moment: Sendable {
        let today: PrayerDay
        let current: PrayerName?
        let next: PrayerName
        let nextTime: Date
        let previousTime: Date

        /// كم مضى من الوقت بين الصلاتين (٠–١)
        func progress(at date: Date) -> Double {
            let total = nextTime.timeIntervalSince(previousTime)
            return total > 0 ? min(max(date.timeIntervalSince(previousTime) / total, 0), 1) : 0
        }
    }

    static func moment(at date: Date, calendar: Calendar = .current) -> Moment? {
        guard let today = day(for: date, calendar: calendar) else { return nil }
        let order = PrayerName.allCases
        if let next = order.first(where: { today.time($0) > date }) {
            let index = order.firstIndex(of: next)!
            let current = index > 0 ? order[index - 1] : nil
            // قبل الفجر: الوقت الماضي هو عشاء الأمس
            let previous = current.map { today.time($0) }
                ?? calendar.date(byAdding: .day, value: -1, to: date).flatMap { day(for: $0, calendar: calendar)?.time(.isha) }
                ?? calendar.startOfDay(for: date)
            return Moment(today: today, current: current, next: next, nextTime: today.time(next), previousTime: previous)
        }
        // بعد العشاء
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        let fajr = day(for: tomorrow, calendar: calendar)?.time(.fajr) ?? tomorrow
        return Moment(today: today, current: .isha, next: .fajr, nextTime: fajr, previousTime: today.time(.isha))
    }

    /// بداية كل وقت صلاة خلال ٢٤ ساعة، ليتغيّر الودجت في وقته
    static func transitions(from date: Date, calendar: Calendar = .current) -> [Date] {
        let days = [date, calendar.date(byAdding: .day, value: 1, to: date) ?? date]
        return days.compactMap { day(for: $0, calendar: calendar) }
            .flatMap { day in PrayerName.allCases.map { day.time($0) } }
            .filter { $0 > date && $0 < date.addingTimeInterval(86_400) }
    }

    // MARK: التنسيق
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ar@numbers=arab")
        f.dateFormat = "h:mm"
        return f
    }()

    /// «٤:٣٦» بدون ص/م، لأن ترتيب الصلوات يوضح الفترة
    static func format(_ date: Date) -> String { timeFormatter.string(from: date) }
}
