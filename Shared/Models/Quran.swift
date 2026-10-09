//
//  Quran.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Foundation

// MARK: - Models

/// آية بنص مجمع الملك فهد (حفص، الإصدار ٣٠). النص كما في ملف المجمع حرفياً،
/// وينتهي برقم الآية الذي يرسمه خط حفص داخل زخرفته.
nonisolated struct Verse: Hashable, Sendable {
    let surah: Int
    let surahName: String
    let number: Int
    let text: String

    /// عدد الحروف بدون التشكيل، لتقدير المساحة التي تحتاجها الآية.
    var letterCount: Int {
        text.unicodeScalars.filter { $0.properties.generalCategory != .nonspacingMark }.count
    }
}

// MARK: - Library

/// المصحف المضمّن في التطبيق (`quran_hafs.json`)، متاح بدون إنترنت للتطبيق والـ Widget.
nonisolated struct QuranLibrary: Sendable {
    let verses: [Verse]

    /// يُحمَّل مرة واحدة عند أول استخدام.
    static let bundled: QuranLibrary = {
        do {
            return try load(from: .main)
        } catch {
            fatalError("Could not load bundled Quran: \(error)")
        }
    }()

    static func load(from bundle: Bundle) throws -> QuranLibrary {
        guard let url = bundle.url(forResource: "quran_hafs", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "quran_hafs.json"])
        }
        let file = try JSONDecoder().decode(QuranFile.self, from: Data(contentsOf: url))
        let verses = file.suras.enumerated().flatMap { index, surah in
            surah.verses.enumerated().map { number, text in
                Verse(surah: index + 1, surahName: surah.name, number: number + 1, text: text)
            }
        }
        return QuranLibrary(verses: verses)
    }

    /// آية تتبدّل مع بداية كل يوم بالتوقيت المحلي. نفس اليوم يعطي نفس الآية دائماً، فيتطابق التطبيق والـ Widget.
    /// القفزة بين الأيام عدد أولي لا يقسم عدد الآيات، فتمر على كل المصحف قبل أن تتكرر.
    /// إذا لم تتسع آية اليوم (`maxLetters`) نأخذ التي تليها.
    func verseOfDay(at date: Date, maxLetters: Int = .max, timeZone: TimeZone = .current) -> Verse? {
        guard !verses.isEmpty else { return nil }
        let localSeconds = date.timeIntervalSinceReferenceDate + Double(timeZone.secondsFromGMT(for: date))
        let day = Int((localSeconds / 86_400).rounded(.down))
        let start = ((day * Self.dailyStep) % verses.count + verses.count) % verses.count
        return (0..<verses.count)
            .lazy
            .map { verses[(start + $0) % verses.count] }
            .first { $0.letterCount <= maxLetters }
    }

    private static let dailyStep = 2459
}

private nonisolated struct QuranFile: Decodable {
    let suras: [Surah]

    struct Surah: Decodable {
        let name: String
        let verses: [String]
    }
}
