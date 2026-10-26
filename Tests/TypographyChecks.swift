import CoreText
import Foundation
import SwiftUI
import UIKit

@main
struct TypographyChecks {
    @MainActor
    static func main() throws {
        let fonts = URL(fileURLWithPath: CommandLine.arguments[1])
        for url in try FileManager.default.contentsOfDirectory(at: fonts, includingPropertiesForKeys: nil) where url.pathExtension == "ttf" {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        precondition(AppFontFamily.unregisteredFonts.isEmpty, "Every registered font and weight must load")
        for family in AppFontFamily.customizable {
            for weight in family.availableWeights {
                precondition(UIFont(name: family.postScriptName(weight: weight), size: 20) != nil)
            }
        }
        precondition(AppFontFamily.amiri.resolvedWeight(for: .light) == .regular)
        precondition(AppFontFamily.ibmPlexArabic.resolvedWeight(for: .black) == .bold)
        var style = WidgetStyle()
        style.contentFont = .lateef
        style.labelFont = .ibmPlexArabic
        style.fontWeight = .medium
        style.labelWeight = .light
        style.titleWeight = .regular
        style.numberWeight = .semibold
        style.fontScale = 1.2
        style.labelScale = 0.9
        style.titleScale = 1.1
        style.numberScale = 0.8
        let encoded = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(WidgetStyle.self, from: encoded)
        precondition(decoded.contentFont == style.contentFont && decoded.labelFont == style.labelFont && decoded.titleFont == style.titleFont)
        precondition(decoded.fontWeight == style.fontWeight && decoded.labelWeight == style.labelWeight
                     && decoded.titleWeight == style.titleWeight && decoded.numberWeight == style.numberWeight)
        precondition(decoded.fontScale == style.fontScale && decoded.labelScale == style.labelScale
                     && decoded.titleScale == style.titleScale && decoded.numberScale == style.numberScale)
        for role in [WidgetFontRole.text, .label, .title, .number, .quran] {
            precondition(decoded.font(role, 20) == style.font(role, 20), "Saved typography must render identically")
        }
        precondition(style.font(.label, 20) == .app(.ibmPlexArabic, size: 18, weight: .light))
        precondition(style.font(.title, 20) == .app(.arefRuqaa, size: 22, weight: .regular))
        precondition(style.font(.number, 20) == NumberFont.rounded.font(size: 16, weight: .semibold, family: .lateef))
        precondition(style.font(.quran, 20) == .app(.uthmanicHafs, size: 24), "Quran keeps its font")
        var legacy = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        for key in ["labelWeight", "titleWeight", "numberWeight", "labelScale", "titleScale", "numberScale"] { legacy.removeValue(forKey: key) }
        let oldStyle = try JSONDecoder().decode(WidgetStyle.self, from: JSONSerialization.data(withJSONObject: legacy))
        precondition(oldStyle.contentFont == .lateef && oldStyle.fontScale == 1.2)
        precondition(oldStyle.labelWeight == nil && oldStyle.numberScale == nil)
        precondition(oldStyle.font(.label, 20) == .app(.ibmPlexArabic, size: 22, weight: .medium), "Legacy label size and weight")
        print("Passed: font registration, supported weights, independent roles, saved styles, legacy settings, Quran font.")
    }
}
