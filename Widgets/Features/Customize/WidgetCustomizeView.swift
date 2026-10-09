//
//  WidgetCustomizeView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - تخصيص الودجت
// التعديلات تظهر مباشرة في المعاينة، ولا تُحفظ إلا بالضغط على «حفظ».
struct WidgetCustomizeView: View {
    let kind: WidgetKind
    @Environment(WidgetStyleStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    /// لتحويل ألوان ColorPicker إلى قيم قابلة للحفظ
    @Environment(\.self) private var environment

    @State private var style: WidgetStyle
    @State private var size: WidgetSize
    @State private var showApplyToAll = false
    @State private var showNewStyleName = false
    @State private var newStyleName = ""
    @State private var styleToDelete: SavedStyle?
    private let original: WidgetStyle

    init(kind: WidgetKind, style: WidgetStyle, size: WidgetSize) {
        self.kind = kind
        self.original = style
        _style = State(initialValue: style)
        _size = State(initialValue: size)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                preview
                ScrollView {
                    VStack(spacing: 20) {
                        savedStylesSection
                        backgroundSection
                        colorsSection
                        fontSection
                        numbersSection
                        if kind.supportsCalligraphy { calligraphySection }
                        actions
                    }
                    .padding(16)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("تخصيص \(kind.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        store.save(style, for: [kind])
                        dismiss()
                    }
                    .bold()
                    .disabled(style == original)
                }
            }
            .confirmationDialog("تطبيق هذا الشكل على كل الودجات؟", isPresented: $showApplyToAll,
                                titleVisibility: .visible) {
                Button("تطبيق على الكل") {
                    store.save(style, for: WidgetKind.allCases)
                    dismiss()
                }
            } message: {
                Text("يستبدل الشكل الحالي لكل الودجات بهذا الشكل.")
            }
            .alert("حفظ كنمط جديد", isPresented: $showNewStyleName) {
                TextField("اسم النمط", text: $newStyleName)
                Button("حفظ") {
                    let name = newStyleName.trimmingCharacters(in: .whitespacesAndNewlines)
                    store.addSavedStyle(named: name.isEmpty ? "نمط \(store.savedStyles.count + 1)" : name, style: style)
                }
                Button("إلغاء", role: .cancel) {}
            } message: {
                Text("يظهر في «تعديل الودجت» لتختاره لأي ودجت.")
            }
            .confirmationDialog("حذف النمط «\(styleToDelete?.name ?? "")»؟",
                                isPresented: Binding(get: { styleToDelete != nil }, set: { if !$0 { styleToDelete = nil } }),
                                titleVisibility: .visible) {
                Button("حذف", role: .destructive) {
                    if let styleToDelete { store.deleteSavedStyle(styleToDelete.id) }
                }
            } message: {
                Text("الودجات التي تستخدمه ترجع لشكل نوعها.")
            }
            // لا يُغلق بالسحب وفيه تعديلات غير محفوظة
            .interactiveDismissDisabled(style != original)
        }
        .tint(Theme.gold)
    }

    // MARK: المعاينة
    private var preview: some View {
        VStack(spacing: 12) {
            WidgetPreviewView(kind: kind, size: size, style: style)
                .aspectRatio(size.aspectRatio, contentMode: .fit)
                .cardStyle(radius: 24)
                .frame(maxWidth: size == .small ? 170 : .infinity, maxHeight: 200)
                .animation(.snappy, value: style)
                .animation(.snappy, value: size)

            if kind.supportedSizes.count > 1 {
                Picker("الحجم", selection: $size) {
                    ForEach(kind.supportedSizes, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
        .background(Theme.background)
    }

    // MARK: الأنماط المحفوظة
    private var savedStylesSection: some View {
        SettingsSection("أنماطي") {
            if !store.savedStyles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(store.savedStyles) { saved in
                            SavedStyleChip(saved: saved, isCurrent: saved.style == style) {
                                withAnimation(.snappy) { style = saved.style }
                            }
                            .contextMenu {
                                Button("تحديث بالشكل الحالي", systemImage: "arrow.triangle.2.circlepath") {
                                    store.updateSavedStyle(saved.id, with: style)
                                }
                                .disabled(saved.style == style)
                                Button("حذف", systemImage: "trash", role: .destructive) {
                                    styleToDelete = saved
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            Button {
                newStyleName = ""
                showNewStyleName = true
            } label: {
                Label("حفظ الشكل الحالي كنمط", systemImage: "plus.circle")
                    .font(AppFont.uiBold(14))
            }
            Text("اختر النمط لأي ودجت في الشاشة الرئيسية: اضغط عليه مطولاً ثم «تعديل الودجت». اضغط مطولاً على النمط هنا لتحديثه أو حذفه.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: الخلفية
    private var backgroundSection: some View {
        SettingsSection("الخلفية") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BackgroundPreset.allCases) { preset in
                        PresetSwatch(preset: preset, isSelected: style.background == .preset(preset)) {
                            withAnimation(.snappy) { style.apply(preset) }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            ColorPicker("لون سادة", selection: solidColor, supportsOpacity: false)
            HStack {
                Text("تدرّج مخصص")
                Spacer()
                ColorPicker("أعلى التدرج", selection: gradientColor(top: true), supportsOpacity: false)
                    .labelsHidden()
                Image(systemName: "arrow.left")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                ColorPicker("أسفل التدرج", selection: gradientColor(top: false), supportsOpacity: false)
                    .labelsHidden()
            }
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
    }

    // MARK: الألوان
    private var colorsSection: some View {
        SettingsSection("الألوان") {
            ColorPicker("لون النص", selection: colorBinding(\.textColor), supportsOpacity: false)
            ColorPicker("لون التمييز", selection: colorBinding(\.accentColor), supportsOpacity: false)
            Text("لون التمييز يظهر في الأيقونات والأشرطة والتفاصيل المهمة. اختيار خلفية جاهزة يضبط الألوان المناسبة لها.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
    }

    // MARK: الخط
    private var fontSection: some View {
        SettingsSection("الخط") {
            SettingRow("خط النص") {
                ChoiceChips(options: AppFontFamily.customizable, selection: $style.contentFont) { family in
                    Text(family.displayName).font(.app(family, size: 16))
                }
            }
            SettingRow("خط العناوين") {
                ChoiceChips(options: AppFontFamily.customizable, selection: $style.labelFont) { family in
                    Text(family.displayName).font(.app(family, size: 16))
                }
            }
            SettingRow("وزن الخط") {
                ChoiceChips(options: AppFontWeight.customizable, selection: $style.fontWeight) { weight in
                    Text(weight.title).font(.app(style.contentFont, size: 15, weight: weight))
                }
            }
            SettingRow("حجم الخط", detail: "\(DateHelper.arabic(Int((style.fontScale * 100).rounded())))٪") {
                HStack(spacing: 12) {
                    Text("أ").font(AppFont.ui(13))
                    Slider(value: $style.fontScale, in: WidgetStyle.fontScaleRange, step: 0.05)
                    Text("أ").font(AppFont.ui(20))
                }
                .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: الأرقام
    private var numbersSection: some View {
        SettingsSection("الأرقام") {
            Picker("شكل الأرقام", selection: $style.numerals) {
                ForEach(Numerals.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            SettingRow("خط الأرقام") {
                ChoiceChips(options: NumberFont.allCases, selection: $style.numberFont) { font in
                    HStack(spacing: 6) {
                        Text(style.numerals.apply("١٢٣"))
                            .font(font.font(size: 15, weight: .bold, family: style.contentFont))
                        Text(font.title).font(AppFont.ui(13))
                    }
                }
            }
        }
    }

    // MARK: الخط العربي
    private var calligraphySection: some View {
        SettingsSection("أسماء الأيام والأشهر") {
            Toggle(isOn: $style.usesCalligraphy) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("بالخط العربي").font(AppFont.ui(15))
                    Text("عند الإيقاف تُكتب بخط النص الذي اخترته")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .foregroundStyle(Theme.textPrimary)
        }
    }

    // MARK: إجراءات
    private var actions: some View {
        VStack(spacing: 12) {
            Button { showApplyToAll = true } label: {
                Label("تطبيق على كل الودجات", systemImage: "square.on.square")
                    .font(AppFont.uiBold(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(Theme.gold)
                    .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            }
            Button {
                withAnimation(.snappy) { style = .default }
            } label: {
                Text("استعادة الشكل الافتراضي")
                    .font(AppFont.ui(14))
                    .foregroundStyle(style == .default ? Theme.textSecondary : Color.red.opacity(0.85))
            }
            .disabled(style == .default)
        }
        .padding(.top, 4)
    }

    // MARK: ربط الألوان
    private func colorBinding(_ keyPath: WritableKeyPath<WidgetStyle, Color.Resolved>) -> Binding<Color> {
        Binding(
            get: { Color(style[keyPath: keyPath]) },
            set: { style[keyPath: keyPath] = $0.resolve(in: environment) }
        )
    }

    private var solidColor: Binding<Color> {
        Binding(
            get: {
                if case .color(let color) = style.background { return Color(color) }
                return Color(currentColors.first ?? BackgroundPreset.night.colors[0])
            },
            set: { style.background = .color($0.resolve(in: environment)) }
        )
    }

    private func gradientColor(top: Bool) -> Binding<Color> {
        Binding(
            get: { Color(top ? currentColors[0] : currentColors[currentColors.count - 1]) },
            set: { newColor in
                let resolved = newColor.resolve(in: environment)
                let colors = currentColors
                style.background = top
                    ? .gradient(resolved, colors[colors.count - 1])
                    : .gradient(colors[0], resolved)
            }
        )
    }

    /// ألوان الخلفية الحالية أياً كان نوعها، نقطة بداية للون أو التدرج المخصص
    private var currentColors: [Color.Resolved] {
        switch style.background {
        case .preset(let preset): preset.colors
        case .color(let color): [color, color]
        case .gradient(let top, let bottom): [top, bottom]
        }
    }
}
