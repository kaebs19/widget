//
//  Azkar.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Foundation

// MARK: - Models

nonisolated struct ZikrGroup: Identifiable, Hashable, Sendable, Decodable {
    let id: Int
    let title: String
    let englishTitle: String

    enum CodingKeys: String, CodingKey {
        case id
        case title = "groupAzkarAr"
        case englishTitle = "groupAzkarEn"
    }

    static let morningID: ID = 1
}

nonisolated struct Zikr: Identifiable, Hashable, Sendable, Decodable {
    let id: Int
    let groupID: ZikrGroup.ID
    let text: String
    /// المصدر أو عنوان فرعي مثل "أدعية السجود"، وقد يكون فارغاً.
    let info: String
    let englishText: String
    let englishInfo: String
    /// عدد مرات التكرار.
    let repeatCount: Int

    /// عدد الحروف بدون التشكيل، لتقدير المساحة التي يحتاجها النص.
    var letterCount: Int {
        text.unicodeScalars.filter { $0.properties.generalCategory != .nonspacingMark }.count
    }

    enum CodingKeys: String, CodingKey {
        case id
        case groupID = "groupId"
        case text = "arAzkar"
        case info = "arInfo"
        case englishText = "enAzkar"
        case englishInfo = "enInfo"
        case repeatCount = "repeat"
    }
}

// MARK: - Library

/// الأذكار المضمّنة في التطبيق (`azkar.json` و `azkar_groups.json`)، متاحة بدون إنترنت للتطبيق والـ Widget.
nonisolated struct AzkarLibrary: Sendable {
    let groups: [ZikrGroup]
    let azkar: [Zikr]
    private let azkarByGroup: [ZikrGroup.ID: [Zikr]]

    init(groups: [ZikrGroup], azkar: [Zikr]) {
        self.groups = groups
        self.azkar = azkar
        azkarByGroup = Dictionary(grouping: azkar, by: \.groupID)
    }

    /// تُحمَّل مرة واحدة عند أول استخدام.
    static let bundled: AzkarLibrary = {
        do {
            return try load(from: .main)
        } catch {
            fatalError("Could not load bundled azkar: \(error)")
        }
    }()

    static func load(from bundle: Bundle) throws -> AzkarLibrary {
        let groups = try decode(GroupList.self, resource: "azkar_groups", in: bundle).groups
        let azkar = try decode(AzkarList.self, resource: "azkar", in: bundle).azkar
        return AzkarLibrary(groups: groups, azkar: azkar)
    }

    func azkar(in groupID: ZikrGroup.ID) -> [Zikr] {
        azkarByGroup[groupID] ?? []
    }

    func group(id: ZikrGroup.ID) -> ZikrGroup? {
        groups.first { $0.id == id }
    }

    func zikr(id: Zikr.ID) -> Zikr? {
        azkar.first { $0.id == id }
    }

    /// ذكر يتبدّل مع بداية كل ساعة بالتوقيت المحلي، من الأذكار التي لا تتجاوز `maxLetters`.
    /// نفس الوقت يعطي نفس الذكر دائماً، فيتطابق التطبيق والـ Widget.
    func rotatingZikr(
        in groupID: ZikrGroup.ID,
        at date: Date,
        maxLetters: Int = .max,
        timeZone: TimeZone = .current
    ) -> Zikr? {
        let candidates = azkar(in: groupID).filter { $0.letterCount <= maxLetters }
        guard !candidates.isEmpty else { return nil }
        let localSeconds = date.timeIntervalSinceReferenceDate + Double(timeZone.secondsFromGMT(for: date))
        let hour = Int((localSeconds / 3600).rounded(.down))
        let count = candidates.count
        return candidates[(hour % count + count) % count]
    }

    private static func decode<T: Decodable>(_ type: T.Type, resource: String, in bundle: Bundle) throws -> T {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "\(resource).json"])
        }
        return try JSONDecoder().decode(type, from: Data(contentsOf: url))
    }
}

private nonisolated struct AzkarList: Decodable {
    let azkar: [Zikr]

    enum CodingKeys: String, CodingKey {
        case azkar = "AzkarList"
    }
}

private nonisolated struct GroupList: Decodable {
    let groups: [ZikrGroup]

    enum CodingKeys: String, CodingKey {
        case groups = "AzkarGroupList"
    }
}
