//
//  WidgetStyle.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - شكل الودجت
// كل ما يخصّصه المستخدم: الخلفية والألوان والخطوط والأرقام.
// يُحفظ لكل نوع ودجت في المساحة المشتركة، ويُمرَّر للعرض عبر البيئة `\.widgetStyle`.
nonisolated struct WidgetStyle: Codable, Hashable, Sendable {
    var background: WidgetBackground = .preset(.night)
    var textColor: Color.Resolved = BackgroundPreset.night.textColor
    var accentColor: Color.Resolved = BackgroundPreset.night.accentColor
    /// خط المحتوى: الأذكار، أسماء المناسبات، «أستغفر الله»
    var contentFont: AppFontFamily = .amiri
    /// خط العناوين الصغيرة والتفاصيل
    var labelFont: AppFontFamily = .tajawal
    /// خط أسماء المناسبات (اليوم الوطني، العيد، المناسبة الخاصة)
    var titleFont: AppFontFamily = .arefRuqaa
    var fontWeight: AppFontWeight = .regular
    var fontScale: Double = 1
    /// nil يحافظ على سلوك الأنماط القديمة، حتى يخصص المستخدم الدور بنفسه.
    var labelWeight: AppFontWeight?
    var titleWeight: AppFontWeight?
    var numberWeight: AppFontWeight?
    var labelScale: Double?
    var titleScale: Double?
    var numberScale: Double?
    var numberFont: NumberFont = .rounded
    /// يبدأ بشكل الأرقام العام من الإعدادات، ويقدر المستخدم يخالفه لودجت معيّن
    var numerals: Numerals = AppSettings.numerals
    /// أسماء الأيام والأشهر بصور الخط العربي بدل النص
    var usesCalligraphy = true

    static let `default` = WidgetStyle()
    static let fontScaleRange: ClosedRange<Double> = 0.8...1.25

    init() {}

    // عند إضافة خاصية جديدة مستقبلاً، الأشكال المحفوظة قديماً تأخذ قيمتها الافتراضية بدل ما تضيع
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = WidgetStyle()
        func value<T: Decodable>(_ key: CodingKeys, _ defaultValue: T) -> T {
            (try? container.decodeIfPresent(T.self, forKey: key)) ?? defaultValue
        }
        background = value(.background, fallback.background)
        textColor = value(.textColor, fallback.textColor)
        accentColor = value(.accentColor, fallback.accentColor)
        contentFont = value(.contentFont, fallback.contentFont)
        labelFont = value(.labelFont, fallback.labelFont)
        titleFont = value(.titleFont, fallback.titleFont)
        fontWeight = value(.fontWeight, fallback.fontWeight)
        fontScale = value(.fontScale, fallback.fontScale)
        labelWeight = value(.labelWeight, fallback.labelWeight)
        titleWeight = value(.titleWeight, fallback.titleWeight)
        numberWeight = value(.numberWeight, fallback.numberWeight)
        labelScale = value(.labelScale, fallback.labelScale)
        titleScale = value(.titleScale, fallback.titleScale)
        numberScale = value(.numberScale, fallback.numberScale)
        numberFont = value(.numberFont, fallback.numberFont)
        numerals = value(.numerals, fallback.numerals)
        usesCalligraphy = value(.usesCalligraphy, fallback.usesCalligraphy)
    }

    /// الخلفية الجاهزة تأتي بألوان نص تناسبها، والمستخدم يقدر يغيّرها بعدها
    mutating func apply(_ preset: BackgroundPreset) {
        background = .preset(preset)
        textColor = preset.textColor
        accentColor = preset.accentColor
    }

    // MARK: الألوان
    var primary: Color { Color(textColor) }
    var secondary: Color { Color(textColor).opacity(0.6) }
    var accent: Color { Color(accentColor) }

    /// لون يقرأ فوق لون التمييز (رقم اليوم المحدد، شريط ورقة التقويم)
    var onAccent: Color {
        let luminance = 0.2126 * accentColor.linearRed + 0.7152 * accentColor.linearGreen + 0.0722 * accentColor.linearBlue
        return luminance > 0.4 ? Color(white: 0.12) : .white
    }

    /// لون يقرأ فوق لون النص (مثل علامة + داخل زر بلون النص)
    var onPrimary: Color {
        let luminance = 0.2126 * textColor.linearRed + 0.7152 * textColor.linearGreen + 0.0722 * textColor.linearBlue
        return luminance > 0.4 ? .black : .white
    }

    // MARK: الخطوط
    func font(_ role: WidgetFontRole, _ size: CGFloat) -> Font {
        let scale = CGFloat(fontScale)
        // العناوين الصغيرة تكبر بنصف المقدار حتى لا تزاحم المحتوى
        let labelSize = size * CGFloat(labelScale ?? (1 + (fontScale - 1) / 2))
        let contentSize = size * scale
        switch role {
        case .label:     return .app(labelFont, size: labelSize, weight: labelWeight ?? .medium)
        case .labelBold: return .app(labelFont, size: labelSize, weight: labelWeight.map { $0.shifted(by: 2) } ?? .bold)
        case .text:      return .app(contentFont, size: contentSize, weight: fontWeight)
        case .textBold:  return .app(contentFont, size: contentSize, weight: fontWeight.shifted(by: 3))
        case .title:     return .app(titleFont, size: size * CGFloat(titleScale ?? fontScale), weight: titleWeight ?? fontWeight.shifted(by: 3))
        case .number:    return numberFont.font(size: size * CGFloat(numberScale ?? fontScale), weight: numberWeight ?? fontWeight.shifted(by: 4), family: contentFont)
        case .quran:     return .app(.uthmanicHafs, size: contentSize)
        }
    }

    /// كم يكبر النص مقارنة بالتصميم الأصلي (خط Amiri بالحجم الافتراضي)، لحساب ما يتسع له الودجت
    var contentSpaceFactor: Double {
        fontScale * fontScale * contentFont.spaceFactor
    }

    // MARK: الأرقام
    @MainActor
    func number(_ value: Int) -> String { numerals.apply(DateHelper.arabic(value)) }

    /// يطبّق شكل الأرقام على أي نص منسّق مسبقاً (تواريخ، عدادات)
    func text(_ value: String) -> String { numerals.apply(value) }
}

nonisolated enum WidgetFontRole: Sendable {
    case label, labelBold, text, textBold, title, number, quran
}

nonisolated enum NumberFont: String, Codable, CaseIterable, Identifiable, Sendable {
    case rounded, standard, serif, monospaced, text

    var id: Self { self }

    var title: String {
        switch self {
        case .rounded:    "مدوّر"
        case .standard:   "عادي"
        case .serif:      "كلاسيكي"
        case .monospaced: "ثابت العرض"
        case .text:       "خط النص"
        }
    }

    func font(size: CGFloat, weight: AppFontWeight, family: AppFontFamily) -> Font {
        switch self {
        case .rounded:    .system(size: size, weight: weight.swiftUIWeight, design: .rounded)
        case .standard:   .system(size: size, weight: weight.swiftUIWeight, design: .default)
        case .serif:      .system(size: size, weight: weight.swiftUIWeight, design: .serif)
        case .monospaced: .system(size: size, weight: weight.swiftUIWeight, design: .monospaced)
        case .text:       .app(family, size: size, weight: weight)
        }
    }
}

// MARK: - خيارات الواجهة
extension AppFontFamily {
    /// الخطوط المتاحة للمستخدم (خط المصحف خاص بالآيات)
    nonisolated static let customizable: [AppFontFamily] = [.amiri, .cairo, .tajawal, .lateef, .ibmPlexArabic, .arefRuqaa]
    /// خطوط أسماء المناسبات: الرقعة أولاً ثم خطوط النص
    nonisolated static let titleChoices: [AppFontFamily] = [.arefRuqaa] + customizable.filter { $0 != .arefRuqaa }

    /// المساحة التي يحتاجها الخط مقارنة بـ Amiri، مقاسة على أذكار الصباح والمساء
    nonisolated var spaceFactor: Double {
        switch self {
        case .amiri, .uthmanicHafs, .arefRuqaa: 1
        case .lateef: 1.1
        case .ibmPlexArabic: 1.28
        case .cairo: 1.28
        case .tajawal: 0.82
        }
    }
}

extension AppFontWeight {
    nonisolated static let customizable: [AppFontWeight] = allCases

    var title: String {
        switch self {
        case .extraLight: "رفيع جداً"
        case .light: "خفيف"
        case .regular: "عادي"
        case .medium: "متوسط"
        case .semibold: "شبه عريض"
        case .bold: "عريض"
        case .extraBold: "عريض جداً"
        case .black: "ثقيل"
        }
    }
}

// MARK: - البيئة
extension EnvironmentValues {
    @Entry var widgetStyle: WidgetStyle = .default
}
