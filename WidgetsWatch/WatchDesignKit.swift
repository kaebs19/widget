//
//  WatchDesignKit.swift
//  WidgetsWatch
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import SwiftUI
import WatchKit

// MARK: - رموز التصميم
// من onboarding-spec.json: الساعة داكنة دائماً بخلفية سوداء، والخط خط النظام
enum W {
    static let background = Color.black
    static let row        = hex(0x232323)
    static let card       = hex(0x202020)
    static let ringTrack  = hex(0x333333)
    static let track      = hex(0x333333)
    static let text       = hex(0xF3F0EA)
    static let muted      = hex(0x9C978E)
    static let toggleOff  = hex(0x3A3A3A)
    static let knobOff    = hex(0xD8D4CC)
    static let cellDark   = hex(0x3A3A3A)
    static let cellDarker = hex(0x2B2B2B)
    static let onAccent   = hex(0x141414)

    static func accent(_ accent: AppAccent = .current) -> Color { hex(accent.hex.dark) }

    static func enter(_ duration: Double) -> Animation { .timingCurve(0.33, 1, 0.68, 1, duration: duration) }
    static func move(_ duration: Double) -> Animation { .timingCurve(0.65, 0, 0.35, 1, duration: duration) }

    /// نقرة خفيفة إن كان الاهتزاز مفعّلاً
    static func tap() {
        guard AppGroup.defaults.object(forKey: AppSettings.Key.haptics) as? Bool ?? true else { return }
        WKInterfaceDevice.current().play(.click)
    }

    private static func hex(_ value: UInt32) -> Color {
        Color(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255,
              blue: Double(value & 0xFF) / 255)
    }
}

// MARK: - الشعار
/// أربعة مربعات، الأعلى من جهة اليمين بلون التمييز. يملأ الإطار الذي يُعطى له.
struct WatchLogo: View {
    var pops: [Double] = [1, 1, 1, 1]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let cell = size * 0.44, gap = size * 0.12
            let cells: [(x: CGFloat, y: CGFloat, color: Color)] = [
                (cell + gap, 0, W.accent()), (0, 0, W.cellDark),
                (cell + gap, cell + gap, W.cellDark), (0, cell + gap, W.cellDarker),
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
            .environment(\.layoutDirection, .leftToRight)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - مفتاح التشغيل
/// المفتاح بحجم ٧٥٪ من مفتاح الآيفون، والمقبض يتجه لنهاية السطر عند التشغيل
struct WatchToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            W.tap()
            withAnimation(W.move(0.25)) { isOn.toggle() }
        } label: {
            Capsule()
                .fill(isOn ? W.accent() : W.toggleOff)
                .frame(width: 39, height: 22.5)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(isOn ? Color(white: 0.08) : W.knobOff)
                        .frame(width: 18, height: 18)
                        .padding(2.25)
                }
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation { Toggle(isOn: $isOn) { EmptyView() } }
    }
}

// MARK: - الاختيار المقسّم
struct WatchSegmented<Value: Hashable>: View {
    let options: [(title: String, value: Value)]
    @Binding var selection: Value
    @Namespace private var thumb

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let isSelected = option.value == selection
                Button {
                    W.tap()
                    withAnimation(W.move(0.3)) { selection = option.value }
                } label: {
                    Text(option.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isSelected ? W.onAccent : W.muted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(W.accent())
                                    .matchedGeometryEffect(id: "thumb", in: thumb)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(2.5)
        .frame(width: 87, height: 25)
        .background(W.track, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - سطر الإعداد
struct WatchRow<Accessory: View>: View {
    let symbol: String
    let title: String
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(W.accent())
            Text(title)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(W.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 4)
            accessory
        }
        .padding(.horizontal, 10)
        .frame(height: 42)
        .background(W.row, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - الزر الرئيسي
struct WatchPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(W.onAccent)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .background(W.accent(), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(W.move(0.15), value: configuration.isPressed)
    }
}

// MARK: - شريط الخطوات
struct WatchStepper: View, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                let fill = min(max(progress - Double(index) + 1, 0), 1)
                Capsule()
                    .fill(W.track)
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule().fill(W.accent()).frame(width: proxy.size.width * fill)
                        }
                    }
                    .clipShape(Capsule())
            }
        }
        .frame(width: 50, height: 3)
    }
}
