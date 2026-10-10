//
//  CustomizeComponents.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - قسم إعدادات
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.uiBold(15))
                .foregroundStyle(Theme.textSecondary)
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.cardTop.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

// MARK: - سطر بعنوان
struct SettingRow<Content: View>: View {
    let title: String
    var detail: String? = nil
    @ViewBuilder let content: Content

    init(_ title: String, detail: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                if let detail {
                    Text(detail).foregroundStyle(Theme.gold)
                }
            }
            .font(AppFont.ui(13))
            .foregroundStyle(Theme.textSecondary)
            content
        }
    }
}

// MARK: - اختيارات على شكل كبسولات
struct ChoiceChips<Value: Hashable, Label: View>: View {
    let options: [Value]
    @Binding var selection: Value
    @ViewBuilder let label: (Value) -> Label

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isOn = option == selection
                    Button {
                        withAnimation(.snappy) { selection = option }
                    } label: {
                        label(option)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(isOn ? Theme.onAccent : Theme.textPrimary)
                            .background(isOn ? AnyShapeStyle(Theme.gold) : AnyShapeStyle(Theme.cardTop), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - مربع خلفية جاهزة
struct PresetSwatch: View {
    let preset: BackgroundPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        Button(action: action) {
            VStack(spacing: 6) {
                WidgetBackgroundView(background: .preset(preset))
                    .overlay {
                        // حرف بلون النص المقترح، يوضح التباين قبل الاختيار
                        Text("أ")
                            .font(AppFont.zikrBold(20))
                            .foregroundStyle(Color(preset.textColor))
                    }
                    .frame(width: 58, height: 58)
                    .clipShape(shape)
                    .overlay(shape.strokeBorder(isSelected ? Theme.gold : Theme.border, lineWidth: isSelected ? 2 : 1))
                Text(preset.title)
                    .font(AppFont.ui(11))
                    .foregroundStyle(isSelected ? Theme.gold : Theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("خلفية \(preset.title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - نمط محفوظ
struct SavedStyleChip: View {
    let saved: SavedStyle
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                WidgetBackgroundView(background: saved.style.background)
                    .overlay {
                        Circle().fill(Color(saved.style.accentColor)).frame(width: 8, height: 8)
                    }
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Theme.border))
                Text(saved.name)
                    .font(.app(saved.style.labelFont, size: 14, weight: .medium))
                    .lineLimit(1)
            }
            .padding(.leading, 6)
            .padding(.trailing, 14)
            .padding(.vertical, 6)
            .foregroundStyle(isCurrent ? Theme.gold : Theme.textPrimary)
            .background(Theme.cardTop, in: Capsule())
            .overlay(Capsule().strokeBorder(isCurrent ? Theme.gold : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}

// MARK: - حقل مبلغ
extension View {
    /// حقل أرقام. لوحة الأرقام وحدها (numberPad) تُخفي النص أثناء الكتابة في واجهتنا المقلوبة للعربية،
    /// فنستخدم لوحة الأرقام والرموز، وتحويل المبلغ يقبل الأرقام العربية والإنجليزية
    func amountField() -> some View {
        keyboardType(.numbersAndPunctuation)
    }
}
