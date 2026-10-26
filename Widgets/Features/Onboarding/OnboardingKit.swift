//
//  OnboardingKit.swift
//  Widgets
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import SwiftUI

// MARK: - رموز التصميم
// من ملف التسليم onboarding-spec.json: الألوان للوضع الداكن كما هي، ومقابل فاتح لها حتى يتبع اختيار المظهر
enum OB {
    static let background = adaptive(dark: 0x121212, light: 0xF4F2EE)
    static let panel      = adaptive(dark: 0x191919, light: 0xFFFFFF)
    static let card       = adaptive(dark: 0x202020, light: 0xF7F5F1)
    static let card2      = adaptive(dark: 0x2F2F2F, light: 0xECE9E3)
    static let line       = adaptive(dark: 0x2A2A2A, light: 0xE4E0D8)
    static let text       = adaptive(dark: 0xF3F0EA, light: 0x1C1B19)
    static let muted      = adaptive(dark: 0x9C978E, light: 0x6E6A63)
    static let dim        = adaptive(dark: 0x5F5B55, light: 0xB3AEA6)
    static let iconTile   = adaptive(dark: 0x26231D, light: 0xF3ECDD)
    static let track      = adaptive(dark: 0x2A2A2A, light: 0xE4E0D8)
    static let toggleOff  = adaptive(dark: 0x3A3A3A, light: 0xD9D5CE)
    static let knobOff    = adaptive(dark: 0xD8D4CC, light: 0xFFFFFF)
    static let ringTrack  = adaptive(dark: 0x333333, light: 0xE4E0D8)
    static let bannerBg   = adaptive(dark: 0x343434, light: 0xFFFFFF, opacity: 0.94)
    static let bannerLine = adaptive(dark: 0x3A3A3A, light: 0xE4E0D8)
    static let cellDark   = adaptive(dark: 0x3A3A3A, light: 0xCFCAC1)
    static let cellDarker = adaptive(dark: 0x2B2B2B, light: 0xE2DED6)
    /// النص فوق لون التمييز دائماً #141414
    static let onAccent   = Color(red: 0x14 / 255, green: 0x14 / 255, blue: 0x14 / 255)

    static var accent: Color { Theme.gold }

    // ثلاثة منحنيات فقط، لا غيرها
    static func enter(_ duration: Double) -> Animation { .timingCurve(0.33, 1, 0.68, 1, duration: duration) }
    static func move(_ duration: Double) -> Animation { .timingCurve(0.65, 0, 0.35, 1, duration: duration) }
    static func pop(_ duration: Double) -> Animation { .timingCurve(0.34, 1.56, 0.64, 1, duration: duration) }

    static func font(_ size: CGFloat, _ weight: AppFontWeight = .regular) -> Font {
        .app(.ibmPlexArabic, size: size, weight: weight)
    }

    private static func adaptive(dark: UInt32, light: UInt32, opacity: CGFloat = 1) -> Color {
        Color(UIColor { traits in
            let hex = traits.userInterfaceStyle == .light ? light : dark
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: opacity)
        })
    }
}

// MARK: - التوقيت
// المشاهد المتحركة تُحسب من الزمن مباشرة كما في ملفات التصميم
enum Ease {
    static func progress(_ t: Double, _ start: Double, _ duration: Double) -> Double {
        min(max((t - start) / duration, 0), 1)
    }

    static func enter(_ t: Double, _ start: Double, _ duration: Double) -> Double {
        1 - pow(1 - progress(t, start, duration), 3)
    }

    static func move(_ t: Double, _ start: Double, _ duration: Double) -> Double {
        let x = progress(t, start, duration)
        return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
    }

    static func pop(_ t: Double, _ start: Double, _ duration: Double) -> Double {
        let x = progress(t, start, duration), c1 = 1.70158, c3 = c1 + 1
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    }
}

// MARK: - الشعار
/// أربعة مربعات بزوايا مدوّرة، الأعلى من جهة اليمين بلون التمييز. يملأ الإطار الذي يُعطى له.
struct WidgetLogo: View {
    /// ظهور كل مربع (٠–١) بالترتيب: أعلى اليمين، أعلى اليسار، أسفل اليمين، أسفل اليسار
    var pops: [Double] = [1, 1, 1, 1]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let cell = size * 0.44, gap = size * 0.12
            let cells: [(x: CGFloat, y: CGFloat, color: Color)] = [
                (cell + gap, 0, OB.accent), (0, 0, OB.cellDark),
                (cell + gap, cell + gap, OB.cellDark), (0, cell + gap, OB.cellDarker),
            ]
            ZStack(alignment: .topLeading) {
                ForEach(cells.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: size * 0.13, style: .continuous)
                        .fill(cells[index].color)
                        .frame(width: cell, height: cell)
                        .scaleEffect(pops[index])
                        .opacity(min(pops[index] * 1.5, 1))
                        .offset(x: cells[index].x, y: cells[index].y)
                }
            }
            .frame(width: size, height: size, alignment: .topLeading)
            // الشعار ثابت لا ينعكس مع اتجاه اللغة
            .environment(\.layoutDirection, .leftToRight)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - مفتاح التشغيل
/// ٥٢×٣٠، والمقبض يتجه لنهاية السطر عند التشغيل (يسار في العربية)
struct OBToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(OB.move(0.25)) { isOn.toggle() }
        } label: {
            Capsule()
                .fill(isOn ? OB.accent : OB.toggleOff)
                .frame(width: 52, height: 30)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(isOn ? Color(white: 0.08) : OB.knobOff)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.4), radius: 1.5, y: 1)
                        .padding(3)
                }
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation { Toggle(isOn: $isOn) { EmptyView() } }
    }
}

// MARK: - الاختيار المقسّم
/// الخيار الأول في بداية السطر (يمين في العربية)، والمؤشر ينزلق بينها
struct OBSegmented<Value: Hashable>: View {
    let options: [(title: String, value: Value)]
    @Binding var selection: Value
    var width: CGFloat = 140
    @Namespace private var thumb

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let isSelected = option.value == selection
                Button {
                    withAnimation(OB.move(0.3)) { selection = option.value }
                } label: {
                    Text(option.title)
                        .font(OB.font(15, .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(isSelected ? OB.onAccent : OB.muted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(OB.accent)
                                    .matchedGeometryEffect(id: "thumb", in: thumb)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .frame(width: width, height: 40)
        .background(OB.track, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - سطر الإعداد
struct OBRow<Accessory: View>: View {
    let symbol: String
    let title: String
    var height: CGFloat = 54
    var isLast = false
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(OB.accent)
                .frame(width: 32, height: 32)
                .background(OB.iconTile, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(title)
                .font(OB.font(15, .medium))
                .foregroundStyle(OB.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            accessory
        }
        .padding(.horizontal, 16)
        .frame(height: height)
        .overlay(alignment: .bottom) {
            if !isLast { Rectangle().fill(OB.line).frame(height: 1) }
        }
    }
}

// MARK: - الزر الرئيسي
struct OBPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(OB.font(17, .bold))
            .foregroundStyle(OB.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(OB.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(OB.move(0.15), value: configuration.isPressed)
    }
}

// MARK: - شريط الخطوات
/// ثلاثة أجزاء تمتلئ من بداية السطر، وتتحرك مع انتقال الصفحة نفسه
struct OBStepper: View, Animatable {
    var progress: Double
    var count = 3

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                let fill = min(max(progress - Double(index) + 1, 0), 1)
                Capsule()
                    .fill(OB.track)
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule().fill(OB.accent).frame(width: proxy.size.width * fill)
                        }
                    }
                    .clipShape(Capsule())
            }
        }
    }
}
