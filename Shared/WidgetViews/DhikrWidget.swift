//
//  DhikrWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - الذكر
struct DhikrWidget: View {
    let zikr: Zikr
    /// سطر المصدر/الفضل تحت الذكر؛ الحجم الصغير ما يتسع له
    var showsInfo = true
    @Environment(\.widgetStyle) private var style

    /// أطول ذكر (بعدد الحروف بدون التشكيل) يتسع له كل حجم دون أن ينقص النص.
    /// مقاسة بخط Amiri على أذكار الصباح والمساء مع هامش أمان ٢٠٪، وتصغر إذا كبّر المستخدم الخط أو اختار خطاً أعرض.
    static func maxLetters(for size: WidgetSize, style: WidgetStyle = .default) -> Int {
        let base: Int
        switch size {
        case .small:  base = 70
        case .medium: base = 150
        case .large:  return .max
        }
        return Int(Double(base) / style.contentSpaceFactor)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeader(icon: .system("sun.max"), title: "أذكار الصباح",
                         trailing: Self.repeatLabel(zikr.repeatCount))
            Text(zikr.text)
                .font(style.font(.text, 17))
                .foregroundStyle(style.primary)
                .lineSpacing(4)
                .minimumScaleFactor(0.8)   // يصغّر الخط شوي لو النص طويل بدل ما ينقص
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            if showsInfo, !zikr.info.isEmpty {
                Text(style.text(zikr.info))
                    .font(style.font(.label, 11))
                    .foregroundStyle(style.secondary)
                    .lineLimit(2)
            }
        }
        .widgetContent()
    }

    /// صيغة العدد بالعربي: مرتان، ٣ مرات، ١٠٠ مرة. المرة الواحدة لا تُكتب.
    static func repeatLabel(_ count: Int) -> String? {
        switch count {
        case ...1:   nil
        case 2:      "مرتان"
        case 3...10: "\(DateHelper.arabic(count)) مرات"
        default:     "\(DateHelper.arabic(count)) مرة"
        }
    }
}

#Preview("أطول ذكر لكل حجم") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach([WidgetSize.small, .medium, .large], id: \.self) { size in
                let longest = AzkarLibrary.bundled.azkar(in: ZikrGroup.morningID)
                    .filter { $0.letterCount <= DhikrWidget.maxLetters(for: size) }
                    .max { $0.letterCount < $1.letterCount }
                if let longest {
                    DhikrWidget(zikr: longest, showsInfo: size != .small)
                        .frame(width: size.size.width, height: size.size.height)
                        .cardStyle()
                }
            }
        }
        .padding()
    }
    .background(Theme.background)
    .environment(\.layoutDirection, .rightToLeft)
    .preferredColorScheme(.dark)
}
