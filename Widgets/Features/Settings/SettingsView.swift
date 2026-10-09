//
//  SettingsView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - الإعدادات
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WidgetStyleStore.self) private var styles
    @State private var showResetAll = false
    @AppStorage(AppSettings.Key.colorScheme, store: AppGroup.defaults) private var colorScheme = ColorSchemeChoice.dark
    @AppStorage(AppSettings.Key.accent, store: AppGroup.defaults) private var accent = AppAccent.gold

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    appearanceSection
                    widgetDefaultsSection
                    aboutSection
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }
                }
            }
        }
        .tint(Theme.gold)
    }

    // MARK: المظهر
    private var appearanceSection: some View {
        SettingsSection("المظهر") {
            SettingRow("الوضع") {
                Picker("الوضع", selection: $colorScheme) {
                    ForEach(ColorSchemeChoice.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            SettingRow("لون التطبيق", detail: accent.title) {
                HStack(spacing: 14) {
                    ForEach(AppAccent.allCases) { option in
                        AccentSwatch(accent: option, isSelected: option == accent) {
                            withAnimation(.snappy) { accent = option }
                        }
                    }
                }
            }
            Text("لون التطبيق للأزرار والاختيارات فقط، وألوان كل ودجت تختارها من صفحته.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: افتراضيات الودجات
    private var defaultStyle: Binding<WidgetStyle> {
        Binding(get: { styles.defaultStyle }, set: { styles.saveDefault($0) })
    }

    private var widgetDefaultsSection: some View {
        SettingsSection("الشكل الافتراضي للودجات") {
            WidgetPreviewView(kind: .hijriDate, size: .medium, style: styles.defaultStyle)
                .aspectRatio(WidgetSize.medium.aspectRatio, contentMode: .fit)
                .cardStyle(radius: 20)
                .animation(.snappy, value: styles.defaultStyle)
            SettingRow("الخلفية") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(BackgroundPreset.allCases) { preset in
                            PresetSwatch(preset: preset, isSelected: styles.defaultStyle.background == .preset(preset)) {
                                withAnimation(.snappy) { defaultStyle.wrappedValue.apply(preset) }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            SettingRow("خط النص") {
                ChoiceChips(options: AppFontFamily.customizable, selection: defaultStyle.contentFont) { family in
                    Text(family.displayName).font(.app(family, size: 16))
                }
            }
            SettingRow("الأرقام") {
                Picker("الأرقام", selection: defaultStyle.numerals) {
                    ForEach(Numerals.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Text("يظهر في كل ودجت ما خصّصته من صفحته. الودجات المخصّصة تبقى على شكلها.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
            Button { showResetAll = true } label: {
                Label("تطبيق على كل الودجات", systemImage: "square.on.square")
                    .font(AppFont.uiBold(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            }
            .confirmationDialog("إلغاء تخصيص كل الودجات؟", isPresented: $showResetAll, titleVisibility: .visible) {
                Button("تطبيق الشكل الافتراضي على الكل", role: .destructive) { styles.resetAllToDefault() }
            } message: {
                Text("كل ودجت خصّصته يرجع للشكل الافتراضي. أنماطك المحفوظة تبقى.")
            }
        }
    }

    // MARK: عن التطبيق
    private var aboutSection: some View {
        SettingsSection("عن التطبيق") {
            HStack {
                Text("الإصدار")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                    .foregroundStyle(Theme.textSecondary)
            }
            Text("نص القرآن الكريم وخطه من مجمع الملك فهد لطباعة المصحف الشريف.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
    }
}

// MARK: - دائرة لون التطبيق
private struct AccentSwatch: View {
    let accent: AppAccent
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let hex = colorScheme == .light ? accent.hex.light : accent.hex.dark
        Button(action: action) {
            Circle()
                .fill(Color(Color.Resolved(hex: hex)))
                .frame(width: 34, height: 34)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(colorScheme == .light ? .white : .black)
                    }
                }
                .overlay(Circle().strokeBorder(Theme.textPrimary.opacity(isSelected ? 0.8 : 0), lineWidth: 2).padding(-4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accent.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
