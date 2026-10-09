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
    var numberFont: NumberFont = .rounded
    var numerals: Numerals = .arabic
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

    /// لون يقرأ فوق لون النص (مثل علامة + داخل زر بلون النص)
    var onPrimary: Color {
        let luminance = 0.2126 * textColor.linearRed + 0.7152 * textColor.linearGreen + 0.0722 * textColor.linearBlue
        return luminance > 0.4 ? .black : .white
    }

    // MARK: الخطوط
    func font(_ role: WidgetFontRole, _ size: CGFloat) -> Font {
        let scale = CGFloat(fontScale)
        // العناوين الصغيرة تكبر بنصف المقدار حتى لا تزاحم المحتوى
        let labelSize = size * (1 + (scale - 1) / 2)
        let contentSize = size * scale
        switch role {
        case .label:     return .app(labelFont, size: labelSize, weight: .medium)
        case .labelBold: return .app(labelFont, size: labelSize, weight: .bold)
        case .text:      return .app(contentFont, size: contentSize, weight: fontWeight)
        case .textBold:  return .app(contentFont, size: contentSize, weight: fontWeight.shifted(by: 3))
        case .title:     return .app(titleFont, size: contentSize, weight: fontWeight.shifted(by: 3))
        case .number:    return numberFont.font(size: contentSize, weight: fontWeight.shifted(by: 4), family: contentFont)
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

// MARK: - الأرقام
nonisolated enum Numerals: String, Codable, CaseIterable, Identifiable, Sendable {
    case arabic, latin

    var id: Self { self }

    var title: String {
        switch self {
        case .arabic: "١٢٣ عربية"
        case .latin:  "123 إنجليزية"
        }
    }

    /// النصوص تُنسّق بالأرقام العربية أصلاً، فنحوّلها للإنجليزية عند الحاجة فقط
    func apply(_ text: String) -> String {
        guard self == .latin else { return text }
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0660...0x0669: scalars.append(Unicode.Scalar(scalar.value - 0x0660 + 0x30)!)
            case 0x066A: scalars.append("%")   // ٪
            case 0x066B: scalars.append(".")   // ٫
            case 0x066C: scalars.append(",")   // ٬
            default: scalars.append(scalar)
            }
        }
        return String(scalars)
    }
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
    nonisolated static let customizable: [AppFontFamily] = [.amiri, .cairo, .tajawal]
    /// خطوط أسماء المناسبات: الرقعة أولاً ثم خطوط النص
    nonisolated static let titleChoices: [AppFontFamily] = [.arefRuqaa] + customizable

    /// المساحة التي يحتاجها الخط مقارنة بـ Amiri، مقاسة على أذكار الصباح والمساء
    nonisolated var spaceFactor: Double {
        switch self {
        case .amiri, .uthmanicHafs, .arefRuqaa: 1
        case .cairo: 1.28
        case .tajawal: 0.82
        }
    }
}

extension AppFontWeight {
    nonisolated static let customizable: [AppFontWeight] = [.light, .regular, .medium, .bold, .black]

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
