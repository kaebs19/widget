import Foundation

@main
struct FeatureChecks {
    @MainActor
    static func main() throws {
        let calendar = DateHelper.gregorian
        func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
        }
        let monthly = Subscription(name: "Monthly", amount: 25, renewalDate: date(2024, 1, 31))
        precondition(monthly.nextRenewal(from: date(2024, 2, 15)) == date(2024, 2, 29), "Leap February")
        precondition(monthly.nextRenewal(from: date(2024, 3, 1)) == date(2024, 3, 31), "Keep original month day")
        precondition(monthly.nextRenewal(from: date(2024, 3, 31, 18)) == date(2024, 3, 31), "Renewal remains today")
        let yearly = Subscription(name: "Yearly", amount: 120, cycle: .yearly, renewalDate: date(2024, 2, 29))
        precondition(yearly.nextRenewal(from: date(2025, 1, 1)) == date(2025, 2, 28), "Annual leap clamping")
        precondition(yearly.monthlyAmount == 10, "Monthly equivalent")
        precondition(yearly.nextRenewal(from: date(2028, 1, 1)) == date(2028, 2, 29), "Leap day recovers")

        let birthday = Occasion(name: "Leap birthday", date: date(2000, 2, 29))
        precondition(birthday.nextDate(from: date(2025, 1, 1)) == date(2025, 2, 28))
        precondition(birthday.nextDate(from: date(2028, 1, 1)) == date(2028, 2, 29))
        precondition(birthday.yearsAtNext(from: date(2025, 1, 1)) == 25)
        let future = Occasion(name: "Future", date: date(2030, 1, 1))
        precondition(future.nextDate(from: date(2026, 1, 1)) == date(2030, 1, 1), "Do not repeat before original event")
        let hijri = DateHelper.hijri
        let original = hijri.date(from: DateComponents(year: 1440, month: 9, day: 1))!
        let now = hijri.date(from: DateComponents(year: 1448, month: 10, day: 1))!
        let occasion = Occasion(name: "Hijri", date: original, calendarType: .hijri)
        let next = hijri.dateComponents([.year, .month, .day], from: occasion.nextDate(from: now))
        precondition(next.year == 1449 && next.month == 9 && next.day == 1, "Hijri annual recurrence")
        precondition(occasion.yearsAtNext(from: now) == 9)
        var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(birthday)) as! [String: Any]
        legacy.removeValue(forKey: "calendarType")
        let decoded = try JSONDecoder().decode(Occasion.self, from: JSONSerialization.data(withJSONObject: legacy))
        precondition(decoded.recurrenceCalendar == .gregorian, "Legacy occasions remain Gregorian")
        let roundTrip = try JSONDecoder().decode(Occasion.self, from: JSONEncoder().encode(occasion))
        precondition(roundTrip.calendarType == .hijri)

        let suite = "com.widgetar.feature-checks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let today = date(2026, 10, 17, 12)
        QuranGoal.setPages(8, on: today, in: defaults)
        precondition(QuranGoal.pages(on: today, in: defaults) == 8)
        precondition(QuranGoal.pages(on: date(2026, 10, 18), in: defaults) == 0, "New daily counter")
        QuranGoal.setPages(-1, on: today, in: defaults)
        precondition(QuranGoal.pages(on: today, in: defaults) == 0)
        QuranGoal.setPages(999, on: today, in: defaults)
        precondition(QuranGoal.pages(on: today, in: defaults) == 604)

        struct Groups: Decodable { let AzkarGroupList: [ZikrGroup] }
        struct Texts: Decodable { let AzkarList: [Zikr] }
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Shared/Resources/Data")
        let groups = try JSONDecoder().decode(Groups.self, from: Data(contentsOf: root.appendingPathComponent("azkar_groups.json"))).AzkarGroupList
        let texts = try JSONDecoder().decode(Texts.self, from: Data(contentsOf: root.appendingPathComponent("azkar.json"))).AzkarList
        let library = AzkarLibrary(groups: groups, azkar: texts)
        for hour in 0..<24 {
            let zikr = library.rotatingZikr(in: ZikrGroup.eveningID, at: today.addingTimeInterval(Double(hour) * 3600), maxLetters: 40)
            precondition(zikr != nil && zikr?.groupID == 2, "Evening texts fit lock screen")
        }
        print("Passed: subscription dates, annual calendars, legacy decoding, daily Quran progress, and evening azkar.")
    }
}
