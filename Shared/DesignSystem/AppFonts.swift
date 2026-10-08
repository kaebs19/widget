//
//  AppFonts.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import UIKit

// MARK: - Weight

/// أوزان الخطوط، مرتبة من الأخف إلى الأثقل.
nonisolated enum AppFontWeight: Int, CaseIterable, Comparable, Sendable {
    case extraLight = 200
    case light = 300
    case regular = 400
    case medium = 500
    case semibold = 600
    case bold = 700
    case extraBold = 800
    case black = 900

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var uiKitWeight: UIFont.Weight {
        switch self {
        case .extraLight: .ultraLight
        case .light: .light
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .extraBold: .heavy
        case .black: .black
        }
    }

    fileprivate var postScriptSuffix: String {
        switch self {
        case .extraLight: "ExtraLight"
        case .light: "Light"
        case .regular: "Regular"
        case .medium: "Medium"
        case .semibold: "SemiBold"
        case .bold: "Bold"
        case .extraBold: "ExtraBold"
        case .black: "Black"
        }
    }
}

// MARK: - Family

/// عائلات الخطوط المضافة إلى المشروع. لإضافة عائلة جديدة: أضف ملفاتها إلى `UIAppFonts` في Info.plist ثم حالة هنا.
nonisolated enum AppFontFamily: String, CaseIterable, Identifiable, Sendable {
    case cairo
    case tajawal
    case amiri
    case uthmanicHafs

    var id: Self { self }

    var displayName: String {
        switch self {
        case .cairo: "القاهرة"
        case .tajawal: "تجوال"
        case .amiri: "أميري"
        case .uthmanicHafs: "عثماني حفص"
        }
    }

    /// الأوزان الموجودة فعلياً كملفات.
    var availableWeights: [AppFontWeight] {
        switch self {
        case .cairo: [.extraLight, .light, .regular, .medium, .semibold, .bold, .extraBold, .black]
        case .tajawal: [.extraLight, .light, .regular, .medium, .bold, .extraBold, .black]
        case .amiri: [.regular, .bold]
        case .uthmanicHafs: [.regular]
        }
    }

    var supportsItalic: Bool { self == .amiri }

    /// أقرب وزن متوفر؛ عند التعادل يُختار الأثقل للأوزان الثقيلة والأخف للخفيفة.
    func resolvedWeight(for weight: AppFontWeight) -> AppFontWeight {
        availableWeights.min { a, b in
            let da = abs(a.rawValue - weight.rawValue)
            let db = abs(b.rawValue - weight.rawValue)
            if da != db { return da < db }
            return weight >= .medium ? a > b : a < b
        } ?? .regular
    }

    /// اسم PostScript المستخدم مع `Font.custom` و `UIFont(name:size:)`.
    func postScriptName(weight: AppFontWeight = .regular, italic: Bool = false) -> String {
        let weight = resolvedWeight(for: weight)
        switch self {
        case .cairo:
            return "Cairo-\(weight.postScriptSuffix)"
        case .tajawal:
            return "Tajawal-\(weight.postScriptSuffix)"
        case .amiri:
            switch (weight == .bold, italic) {
            case (false, false): return "Amiri-Regular"
            case (true, false): return "Amiri-Bold"
            case (false, true): return "Amiri-Italic"
            case (true, true): return "Amiri-BoldItalic"
            }
        case .uthmanicHafs:
            return "KFGQPCUthmanicScriptHAFS"
        }
    }

    var allPostScriptNames: [String] {
        let italics = supportsItalic ? [false, true] : [false]
        return italics.flatMap { italic in
            availableWeights.map { postScriptName(weight: $0, italic: italic) }
        }
    }

    /// الخطوط التي لم يتم تسجيلها (ملف ناقص أو غير مذكور في `UIAppFonts`).
    static var unregisteredFonts: [String] {
        allCases.flatMap(\.allPostScriptNames).filter { UIFont(name: $0, size: 12) == nil }
    }

    /// في وضع التطوير يتوقف التطبيق عند وجود خط غير مسجّل، بدل أن يظهر خط النظام بصمت.
    static func validateRegistration() {
        #if DEBUG
        let missing = unregisteredFonts
        assert(missing.isEmpty, "خطوط غير مسجّلة في Info.plist: \(missing.joined(separator: ", "))")
        #endif
    }
}

// MARK: - Role

/// دور الخط في التطبيق، ويُربط كل دور بعائلة داخل `Typography`.
nonisolated enum AppFontRole: Hashable, Sendable {
    /// نصوص الواجهة: عناوين، أزرار، قوائم.
    case interface
    /// النصوص الطويلة: أذكار، أحاديث، مقالات.
    case reading
    /// الآيات القرآنية.
    case quran
}

// MARK: - Text Style

nonisolated struct TextStyleSpec: Hashable, Sendable {
    var size: CGFloat
    var weight: AppFontWeight = .regular
    var role: AppFontRole = .interface
}

/// أنماط النص. الأحجام الافتراضية تطابق أحجام iOS عند حجم النص الافتراضي.
nonisolated enum AppTextStyle: CaseIterable, Hashable, Sendable {
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
    case caption2
    case reading
    case quran

    var defaultSpec: TextStyleSpec {
        switch self {
        case .largeTitle: TextStyleSpec(size: 34, weight: .bold)
        case .title: TextStyleSpec(size: 28, weight: .bold)
        case .title2: TextStyleSpec(size: 22, weight: .semibold)
        case .title3: TextStyleSpec(size: 20, weight: .semibold)
        case .headline: TextStyleSpec(size: 17, weight: .semibold)
        case .body: TextStyleSpec(size: 17)
        case .callout: TextStyleSpec(size: 16)
        case .subheadline: TextStyleSpec(size: 15)
        case .footnote: TextStyleSpec(size: 13)
        case .caption: TextStyleSpec(size: 12)
        case .caption2: TextStyleSpec(size: 11)
        case .reading: TextStyleSpec(size: 20, role: .reading)
        case .quran: TextStyleSpec(size: 28, role: .quran)
        }
    }

    /// النمط الذي يتبعه الخط عند تغيير حجم النص من إعدادات النظام.
    var dynamicTypeStyle: Font.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .body, .reading: .body
        case .callout: .callout
        case .subheadline: .subheadline
        case .footnote: .footnote
        case .caption: .caption
        case .caption2: .caption2
        case .quran: .title
        }
    }
}

// MARK: - Typography

/// إعدادات الخطوط للتطبيق كاملاً. تُمرَّر عبر البيئة بـ `.typography(_:)` وتنعكس على كل ما تحتها.
nonisolated struct Typography: Hashable, Sendable {
    var interface: AppFontFamily = .tajawal
    var reading: AppFontFamily = .amiri
    var quran: AppFontFamily = .uthmanicHafs
    /// مضاعف عام للأحجام (1 = الافتراضي).
    var scale: CGFloat = 1
    /// عند `false` تبقى الأحجام ثابتة ولا تتأثر بحجم النص في النظام.
    var supportsDynamicType = true
    /// تخصيص نمط معيّن بدل قيمته الافتراضية.
    var overrides: [AppTextStyle: TextStyleSpec] = [:]

    static let `default` = Typography()

    func family(for role: AppFontRole) -> AppFontFamily {
        switch role {
        case .interface: interface
        case .reading: reading
        case .quran: quran
        }
    }

    func spec(for style: AppTextStyle) -> TextStyleSpec {
        overrides[style] ?? style.defaultSpec
    }

    func font(_ style: AppTextStyle, weight: AppFontWeight? = nil, italic: Bool = false) -> Font {
        let (name, size, _) = resolve(style, weight: weight, italic: italic)
        return supportsDynamicType
            ? .custom(name, size: size, relativeTo: style.dynamicTypeStyle)
            : .custom(name, fixedSize: size)
    }

    /// للاستخدام مع واجهات UIKit مثل `UINavigationBarAppearance`.
    func uiFont(_ style: AppTextStyle, weight: AppFontWeight? = nil, italic: Bool = false) -> UIFont {
        let (name, size, weight) = resolve(style, weight: weight, italic: italic)
        let font = UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight.uiKitWeight)
        guard supportsDynamicType else { return font }
        return UIFontMetrics(forTextStyle: style.dynamicTypeStyle.uiKitTextStyle).scaledFont(for: font)
    }

    private func resolve(
        _ style: AppTextStyle,
        weight: AppFontWeight?,
        italic: Bool
    ) -> (name: String, size: CGFloat, weight: AppFontWeight) {
        let spec = spec(for: style)
        let weight = weight ?? spec.weight
        let name = family(for: spec.role).postScriptName(weight: weight, italic: italic)
        return (name, spec.size * scale, weight)
    }
}

private nonisolated extension Font.TextStyle {
    var uiKitTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        @unknown default: .body
        }
    }
}

// MARK: - Design Shortcuts

/// اختصارات التصميم بأحجام محددة، تتبع عائلات `Typography.default` فتبقى متناسقة مع بقية التطبيق.
nonisolated enum AppFont {
    static func quran(_ size: CGFloat) -> Font    { .app(Typography.default.quran, size: size) }
    static func zikr(_ size: CGFloat) -> Font     { .app(Typography.default.reading, size: size) }
    static func zikrBold(_ size: CGFloat) -> Font { .app(Typography.default.reading, size: size, weight: .bold) }
    static func ui(_ size: CGFloat) -> Font       { .app(Typography.default.interface, size: size, weight: .medium) }
    static func uiBold(_ size: CGFloat) -> Font   { .app(Typography.default.interface, size: size, weight: .bold) }

    /// الأرقام الكبيرة بخط النظام المدوّر
    static func number(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}

// MARK: - SwiftUI

extension EnvironmentValues {
    @Entry var typography: Typography = .default
}

nonisolated extension Font {
    /// خط من عائلة محددة بحجم ووزن محددين، لحالات خارج أنماط `AppTextStyle`.
    static func app(
        _ family: AppFontFamily,
        size: CGFloat,
        weight: AppFontWeight = .regular,
        italic: Bool = false,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom(family.postScriptName(weight: weight, italic: italic), size: size, relativeTo: textStyle)
    }
}

extension View {
    /// يطبّق نمط خط من `Typography` الموجود في البيئة.
    func appFont(_ style: AppTextStyle, weight: AppFontWeight? = nil, italic: Bool = false) -> some View {
        modifier(AppFontModifier(style: style, weight: weight, italic: italic))
    }

    /// يستبدل إعدادات الخطوط لهذا الجزء من الواجهة وما تحته.
    func typography(_ typography: Typography) -> some View {
        environment(\.typography, typography)
    }
}

private struct AppFontModifier: ViewModifier {
    @Environment(\.typography) private var typography
    let style: AppTextStyle
    let weight: AppFontWeight?
    let italic: Bool

    func body(content: Content) -> some View {
        content.font(typography.font(style, weight: weight, italic: italic))
    }
}

// MARK: - Previews

#Preview("العائلات والأوزان") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(AppFontFamily.allCases) { family in
                VStack(alignment: .leading, spacing: 6) {
                    Text(family.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(family.availableWeights, id: \.self) { weight in
                        Text("بسم الله الرحمن الرحيم · \(family.postScriptName(weight: weight))")
                            .font(.app(family, size: 20, weight: weight))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    .environment(\.layoutDirection, .rightToLeft)
}

#Preview("أنماط النص") {
    List(AppTextStyle.allCases, id: \.self) { style in
        Text("نص تجريبي · \(String(describing: style))")
            .appFont(style)
    }
    .environment(\.layoutDirection, .rightToLeft)
}
