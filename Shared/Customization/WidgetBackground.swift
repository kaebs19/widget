//
//  WidgetBackground.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - الخلفية
nonisolated enum WidgetBackground: Codable, Hashable, Sendable {
    case preset(BackgroundPreset)
    case color(Color.Resolved)
    case gradient(Color.Resolved, Color.Resolved)
    /// صورة من ألبوم المستخدم، بمعرّفها في `BackgroundImageStore`
    case photo(String)

    var photoID: String? {
        if case .photo(let id) = self { id } else { nil }
    }
}

// MARK: - الخلفيات الجاهزة
// كل خلفية تأتي بلون نص ولون تمييز مقروءين فوقها
nonisolated enum BackgroundPreset: String, Codable, CaseIterable, Identifiable, Sendable {
    case night, golden, pattern, emerald, navy, violet, rose, teal, dawn, national, sand, pearl

    var id: Self { self }

    var title: String {
        switch self {
        case .night:    "ليلي"
        case .golden:   "ذهبي"
        case .pattern:  "نقش"
        case .emerald:  "زمردي"
        case .navy:     "كحلي"
        case .violet:   "بنفسجي"
        case .rose:     "عنّابي"
        case .teal:     "فيروزي"
        case .dawn:     "فجر"
        case .national: "وطني"
        case .sand:     "رملي"
        case .pearl:    "لؤلؤي"
        }
    }

    /// ألوان التدرج من الأعلى للأسفل
    var colors: [Color.Resolved] {
        switch self {
        case .night:    [.init(hex: 0x2B2B2B), .init(hex: 0x1A1A1A)]
        case .golden:   [.init(hex: 0x2A2112), .init(hex: 0x120E07)]
        case .pattern:  [.init(hex: 0x221D17), .init(hex: 0x0F0D0A)]
        case .emerald:  [.init(hex: 0x0F4A37), .init(hex: 0x072A1F)]
        case .navy:     [.init(hex: 0x1B2A4A), .init(hex: 0x0B1326)]
        case .violet:   [.init(hex: 0x33215C), .init(hex: 0x150D29)]
        case .rose:     [.init(hex: 0x4A1F2E), .init(hex: 0x210D15)]
        case .teal:     [.init(hex: 0x0F4650), .init(hex: 0x06262B)]
        case .dawn:     [.init(hex: 0x2E3163), .init(hex: 0xC9806A)]
        case .national: [.init(hex: 0x00753A), .init(hex: 0x004B26)]
        case .sand:     [.init(hex: 0xF4EADB), .init(hex: 0xE3D2B4)]
        case .pearl:    [.init(hex: 0xFBFAF7), .init(hex: 0xECEAE4)]
        }
    }

    var textColor: Color.Resolved {
        switch self {
        case .golden: .init(hex: 0xF6EBD3)
        case .rose:   .init(hex: 0xFFF4F6)
        case .sand:   .init(hex: 0x3A2E1F)
        case .pearl:  .init(hex: 0x1E1E1E)
        default:      .init(hex: 0xFFFFFF)
        }
    }

    var accentColor: Color.Resolved {
        switch self {
        case .night:    .init(hex: 0xEBCC8C)
        case .golden:   .init(hex: 0xE5C27A)
        case .pattern:  .init(hex: 0xE2C383)
        case .emerald:  .init(hex: 0xE8D9A8)
        case .navy:     .init(hex: 0xC8D8FF)
        case .violet:   .init(hex: 0xCDB8FF)
        case .rose:     .init(hex: 0xF4B6C5)
        case .teal:     .init(hex: 0x9FE7DA)
        case .dawn:     .init(hex: 0xFFE2A9)
        case .national: .init(hex: 0xF1EBD9)
        case .sand:     .init(hex: 0x9A6B28)
        case .pearl:    .init(hex: 0xA88247)
        }
    }
}

nonisolated extension Color.Resolved {
    init(hex: UInt32, opacity: Float = 1) {
        self.init(red: Float((hex >> 16) & 0xFF) / 255,
                  green: Float((hex >> 8) & 0xFF) / 255,
                  blue: Float(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

// MARK: - الرسم
struct WidgetBackgroundView: View {
    let background: WidgetBackground

    var body: some View {
        switch background {
        case .preset(let preset):
            LinearGradient(colors: preset.colors.map { Color($0) }, startPoint: .top, endPoint: .bottom)
                .overlay {
                    if preset == .golden {
                        RadialGradient(colors: [Color(preset.accentColor).opacity(0.22), .clear],
                                       center: .topTrailing, startRadius: 0, endRadius: 240)
                    }
                }
                .overlay {
                    if preset == .pattern {
                        IslamicPattern(color: Color(preset.accentColor))
                    }
                }
        case .color(let color):
            Color(color)
        case .gradient(let top, let bottom):
            LinearGradient(colors: [Color(top), Color(bottom)], startPoint: .top, endPoint: .bottom)
        case .photo(let id):
            if let image = BackgroundImageStore.image(for: id) {
                // تعتيم خفيف حتى يُقرأ النص فوق أي صورة
                Color.clear
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .overlay(Color.black.opacity(0.3))
                    .clipped()
            } else {
                WidgetBackgroundView(background: .preset(.night))
            }
        }
    }
}

/// نقش نجمة ثمانية متكرر (مربعان أحدهما مدوّر ٤٥°)، يُرسم مرة واحدة بـ Canvas
struct IslamicPattern: View {
    var color: Color
    var spacing: CGFloat = 34

    var body: some View {
        Canvas { context, size in
            let radius = spacing * 0.32
            var path = Path()
            var row = 0
            var y: CGFloat = 0
            while y <= size.height + spacing {
                var x: CGFloat = row.isMultiple(of: 2) ? 0 : spacing / 2
                while x <= size.width + spacing {
                    let square = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    let rotation = CGAffineTransform.identity
                        .translatedBy(x: x, y: y)
                        .rotated(by: .pi / 4)
                        .translatedBy(x: -x, y: -y)
                    path.addRect(square)
                    path.addPath(Path(square).applying(rotation))
                    x += spacing
                }
                y += spacing
                row += 1
            }
            context.stroke(path, with: .color(color.opacity(0.16)), lineWidth: 0.8)
        }
    }
}
