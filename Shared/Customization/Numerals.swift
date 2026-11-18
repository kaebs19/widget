//
//  Numerals.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Foundation

// MARK: - الأرقام
nonisolated enum Numerals: String, Codable, CaseIterable, Identifiable, Sendable {
    case arabic, latin

    var id: Self { self }

    var title: String { L10n.text(titleKey) }


    private var titleKey: String {
        switch self {
        case .arabic: "١٢٣ عربية"
        case .latin:  "123 إنجليزية"
        }
    }

    /// يحوّل أرقام النص لهذا الشكل في الاتجاهين، لأن النص قد يأتي بالشكل العام للتطبيق
    func apply(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            switch (self, scalar.value) {
            case (.latin, 0x0660...0x0669): scalars.append(Unicode.Scalar(scalar.value - 0x0660 + 0x30)!)
            case (.latin, 0x066A): scalars.append("%")   // ٪
            case (.latin, 0x066B): scalars.append(".")   // ٫
            case (.latin, 0x066C): scalars.append(",")   // ٬
            case (.arabic, 0x30...0x39): scalars.append(Unicode.Scalar(scalar.value - 0x30 + 0x0660)!)
            default: scalars.append(scalar)
            }
        }
        return String(scalars)
    }
}
