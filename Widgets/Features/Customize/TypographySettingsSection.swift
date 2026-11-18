import SwiftUI

/// نفس خيارات الخط في الإعدادات العامة وتخصيص كل ودجت.
struct TypographySettingsSection: View {
    @Binding var style: WidgetStyle
    var isQuran = false
    @State private var part: Part = .content

    private enum Part: String, CaseIterable, Identifiable {
        case content, labels, title, numbers
        var id: Self { self }
        var name: String {
            switch self {
            case .content: L10n.text("النص")
            case .labels: L10n.text("العناوين")
            case .title: L10n.text("اسم المناسبة")
            case .numbers: L10n.text("الأرقام")
            }
        }
        var role: WidgetFontRole {
            switch self {
            case .content: .text
            case .labels: .label
            case .title: .title
            case .numbers: .number
            }
        }
    }

    private var fixedQuran: Bool { isQuran && part == .content }
    private var family: Binding<AppFontFamily> {
        switch part {
        case .content, .numbers: $style.contentFont
        case .labels: $style.labelFont
        case .title: $style.titleFont
        }
    }
    private var weights: [AppFontWeight] {
        part == .numbers && style.numberFont != .text ? AppFontWeight.allCases : family.wrappedValue.availableWeights
    }
    private var weight: Binding<AppFontWeight> {
        Binding(get: {
            let requested: AppFontWeight
            switch part {
            case .content: requested = style.fontWeight
            case .labels: requested = style.labelWeight ?? .medium
            case .title: requested = style.titleWeight ?? style.fontWeight.shifted(by: 3)
            case .numbers: requested = style.numberWeight ?? style.fontWeight.shifted(by: 4)
            }
            return part == .numbers && style.numberFont != .text ? requested : family.wrappedValue.resolvedWeight(for: requested)
        }, set: { value in
            switch part {
            case .content: style.fontWeight = value
            case .labels: style.labelWeight = value
            case .title: style.titleWeight = value
            case .numbers: style.numberWeight = value
            }
        })
    }
    private var scale: Binding<Double> {
        Binding(get: {
            switch part {
            case .content: style.fontScale
            case .labels: style.labelScale ?? (1 + (style.fontScale - 1) / 2)
            case .title: style.titleScale ?? style.fontScale
            case .numbers: style.numberScale ?? style.fontScale
            }
        }, set: { value in
            let bounded = min(max(value, WidgetStyle.fontScaleRange.lowerBound), WidgetStyle.fontScaleRange.upperBound)
            switch part {
            case .content: style.fontScale = bounded
            case .labels: style.labelScale = bounded
            case .title: style.titleScale = bounded
            case .numbers: style.numberScale = bounded
            }
        })
    }

    var body: some View {
        SettingsSection(L10n.text("الخطوط والحجم")) {
            ChoiceChips(options: Part.allCases, selection: $part) { item in
                Text(item.name).font(AppFont.ui(13))
            }
            Text(sample)
                .font(style.font(fixedQuran ? .quran : part.role, 24))
                .foregroundStyle(style.primary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 72)
                .padding(8)
                .background { WidgetBackgroundView(background: style.background) }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityLabel(String(format: L10n.text("معاينة %@: %@"), part.name, sample))

            if fixedQuran {
                Text(L10n.text("الآيات بخط المصحف العثماني. يمكنك تغيير حجمها، وتخصيص خط العناوين والأرقام بشكل مستقل."))
                    .font(AppFont.ui(12))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                if part == .numbers {
                    SettingRow(L10n.text("نوع الأرقام")) {
                        ChoiceChips(options: NumberFont.allCases, selection: $style.numberFont) { font in
                            Text(font.title).font(font.font(size: 14, weight: .medium, family: style.contentFont))
                        }
                        if style.numberFont == .text {
                            Text(L10n.text("يستخدم خط النص الذي اخترته في تبويب «النص»."))
                                .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
                        }
                    }
                } else {
                    fontChoices
                }
                SettingRow(L10n.text("وزن الخط"), detail: weight.wrappedValue.title) {
                    ChoiceChips(options: weights, selection: weight) { value in
                        Text(value.title)
                            .font(part == .numbers ? style.numberFont.font(size: 14, weight: value, family: style.contentFont)
                                  : .app(family.wrappedValue, size: 15, weight: value))
                    }
                }
            }
            SettingRow(String(format: L10n.text("حجم %@"), part.name), detail: String(format: L10n.text("%@٪"), DateHelper.arabic(Int((scale.wrappedValue * 100).rounded())))) {
                HStack(spacing: 12) {
                    Button { scale.wrappedValue -= 0.05 } label: { Image(systemName: "minus") }
                        .disabled(scale.wrappedValue <= WidgetStyle.fontScaleRange.lowerBound)
                        .accessibilityLabel(String(format: L10n.text("تصغير %@"), part.name))
                        .frame(minWidth: 44, minHeight: 44)
                    Slider(value: scale, in: WidgetStyle.fontScaleRange, step: 0.05)
                        .accessibilityLabel(String(format: L10n.text("حجم %@"), part.name))
                        .accessibilityValue(String(format: L10n.text("%lld بالمئة"), Int((scale.wrappedValue * 100).rounded())))
                    Button { scale.wrappedValue += 0.05 } label: { Image(systemName: "plus") }
                        .disabled(scale.wrappedValue >= WidgetStyle.fontScaleRange.upperBound)
                        .accessibilityLabel(String(format: L10n.text("تكبير %@"), part.name))
                        .frame(minWidth: 44, minHeight: 44)
                }
                Button(L10n.text("الحجم الأصلي · ١٠٠٪")) { scale.wrappedValue = 1 }
                    .font(AppFont.ui(12))
            }
            Text(L10n.text("كل حجم نسبة إلى تصميم الودجت. العناوين البارزة تحتفظ بوزن أثقل لتبقى واضحة."))
                .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
        }
    }

    private var sample: String {
        switch part {
        case .content: fixedQuran ? "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ" : "بداية يوم جميل · الحمد لله"
        case .labels: "الصلاة القادمة · التاريخ الهجري"
        case .title: "مناسبتي الجميلة"
        case .numbers: style.text("١٢٣٤٥ · ١٢:٣٠")
        }
    }

    private var fontChoices: some View {
        SettingRow(L10n.text("نوع الخط"), detail: family.wrappedValue.displayName) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
                ForEach(AppFontFamily.customizable) { item in
                    let selected = item == family.wrappedValue
                    Button { family.wrappedValue = item } label: {
                        VStack(spacing: 7) {
                            HStack {
                                Text(item.displayName).font(AppFont.ui(12))
                                Spacer(minLength: 2)
                                if selected { Image(systemName: "checkmark.circle.fill") }
                            }
                            Text("أبجد هوز · ١٢٣")
                                .font(.app(item, size: 20, weight: weight.wrappedValue))
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .padding(12)
                        .foregroundStyle(selected ? Theme.gold : Theme.textPrimary)
                        .background(Theme.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? Theme.gold : Theme.border))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(format: L10n.text("خط %@"), item.displayName))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }
}
