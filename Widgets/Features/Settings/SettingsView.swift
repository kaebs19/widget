//
//  SettingsView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - الإعدادات
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WidgetStyleStore.self) private var styles
    @State private var showResetAll = false
    @State private var showResetCounter = false
    @State private var showHowTo = false
    @State private var webPage: URL?
    @Environment(\.openURL) private var openURL
    @AppStorage(AppSettings.Key.haptics, store: AppGroup.defaults) private var haptics = true
    @AppStorage(AppSettings.Key.hijriOffset, store: AppGroup.defaults) private var hijriOffset = 0
    @AppStorage(AppSettings.Key.weekStart, store: AppGroup.defaults) private var weekStart = 1
    @AppStorage(AppSettings.Key.colorScheme, store: AppGroup.defaults) private var colorScheme = ColorSchemeChoice.dark
    @AppStorage(AppSettings.Key.accent, store: AppGroup.defaults) private var accent = AppAccent.gold

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    group("المحتوى") {
                        row(.prayer)
                        row(.health)
                        row(.occasions)
                        row(.finance)
                        row(.counter)
                    }
                    group("الشكل") {
                        row(.appearance)
                        row(.widgetDefaults)
                    }
                    group("عام") {
                        row(.calendar)
                        row(.about)
                    }
                    group("الدعم") {
                        actionRow("طريقة الإضافة", "للشاشة الرئيسية وشاشة القفل", symbol: "questionmark.circle.fill",
                                  color: Color(red: 0.20, green: 0.60, blue: 0.86), chevron: true) { showHowTo = true }
                        actionRow("الأسئلة الشائعة", "إجابات سريعة لأكثر الأسئلة", symbol: "bubble.left.and.text.bubble.right.fill",
                                  color: Color(red: 0.36, green: 0.42, blue: 0.86), external: true) { webPage = AppLinks.faq }
                        actionRow("تواصل معنا", AppLinks.supportEmail, symbol: "envelope.fill",
                                  color: Color(red: 0.18, green: 0.62, blue: 0.52), external: true) {
                            if let url = AppLinks.mail(subject: "دعم تطبيق ويدجت") { openURL(url) }
                        }
                        actionRow("إبلاغ عن خطأ في نص", "آية أو ذكر يحتاج تصحيح", symbol: "exclamationmark.bubble.fill",
                                  color: Color(red: 0.90, green: 0.45, blue: 0.20), external: true) {
                            if let url = AppLinks.mail(subject: "خطأ في نص",
                                                       body: "اسم الودجت:\nالنص الذي فيه الخطأ:\nالتصحيح المقترح:\n") {
                                openURL(url)
                            }
                        }
                        actionRow("قيّم التطبيق", "رأيك يساعدنا نتحسّن", symbol: "star.fill",
                                  color: Color(red: 0.95, green: 0.70, blue: 0.15), external: true) { openURL(AppLinks.writeReview) }
                        ShareLink(item: AppLinks.appStore,
                                  message: Text("جرّب تطبيق ويدجت: ودجات الصلاة والأذكار والتقويم الهجري")) {
                            rowLabel("شارك التطبيق", "أرسله لمن تحب", symbol: "square.and.arrow.up.fill",
                                     color: Color(red: 0.55, green: 0.42, blue: 0.85))
                        }
                        .buttonStyle(.plain)
                        actionRow("تابعنا على X", "@B_c_Arab", symbol: "at",
                                  color: Color(white: 0.2), external: true) { openURL(AppLinks.x) }
                    }
                    group("قانوني") {
                        actionRow("سياسة الخصوصية", "كيف نتعامل مع بياناتك", symbol: "hand.raised.fill",
                                  color: Color(red: 0.25, green: 0.52, blue: 0.90), external: true) { webPage = AppLinks.privacy }
                        actionRow("شروط الاستخدام", "شروط التطبيق والاشتراك", symbol: "doc.text.fill",
                                  color: Color(white: 0.5), external: true) { webPage = AppLinks.terms }
                        NavigationLink { CreditsView() } label: {
                            rowLabel("المصادر والتراخيص", "مصادر النصوص والخطوط والمكتبات", symbol: "books.vertical.fill",
                                     color: Color(red: 0.62, green: 0.48, blue: 0.30), chevron: true)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("ويدجت \(AppLinks.version)")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
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
            .navigationDestination(for: SettingsPage.self) { page in
                destination(page)
            }
            .sheet(isPresented: $showHowTo) { HowToAddView().appAppearance() }
            .sheet(item: $webPage) { url in SafariView(url: url).ignoresSafeArea() }
        }
        .tint(Theme.gold)
    }

    // MARK: الصفحة الرئيسية
    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 26))
                .foregroundStyle(Theme.onAccent)
                .frame(width: 60, height: 60)
                .background(Theme.gold, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("ويدجت").font(AppFont.uiBold(20))
                Text("خصّص ودجاتك وأوقات صلاتك ومناسباتك")
                    .font(AppFont.ui(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(16)
        .background(Theme.cardTop.opacity(0.6), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.uiBold(14))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 6)
            VStack(spacing: 0) {
                content()
            }
            .background(Theme.cardTop.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func row(_ page: SettingsPage) -> some View {
        NavigationLink(value: page) {
            HStack(spacing: 12) {
                Image(systemName: page.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(page.color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(page.title).font(AppFont.uiBold(15))
                    Text(summary(page))
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// سطر يفتح رابطاً أو ينفّذ إجراءً بدل صفحة
    private func actionRow(_ title: String, _ subtitle: String, symbol: String, color: Color,
                           external: Bool = false, chevron: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowLabel(title, subtitle, symbol: symbol, color: color, chevron: chevron, external: external)
        }
        .buttonStyle(.plain)
    }

    private func rowLabel(_ title: String, _ subtitle: String, symbol: String, color: Color,
                          chevron: Bool = false, external: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.uiBold(15))
                Text(subtitle)
                    .font(AppFont.ui(12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            if external || chevron {
                Image(systemName: external ? "arrow.up.left" : "chevron.left")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    /// سطر صغير تحت كل قسم يلخّص إعداده الحالي
    private func summary(_ page: SettingsPage) -> String {
        switch page {
        case .prayer:
            "\(PrayerLocation.current.city) · \(PrayerSchedule.method.title)"
        case .occasions:
            OccasionStore.all().isEmpty ? "أعياد الميلاد والذكريات" : "\(DateHelper.arabic(OccasionStore.all().count)) مناسبة"
        case .health:
            HealthCache.isConnected
                ? HealthCache.load().map { "\(HealthMetric.steps.format($0.value(.steps))) خطوة اليوم" } ?? "مربوط بتطبيق الصحة"
                : "الخطوات والسعرات والنوم"
        case .finance:
            Payday.allCases.map { $0.cycle() }.min { $0.next < $1.next }
                .map { "\($0.payday.displayName) \(PaydayFormat.remaining($0.days))" } ?? ""
        case .counter:
            haptics ? "الاهتزاز مفعّل" : "الاهتزاز متوقف"
        case .appearance:
            "\(colorScheme.title) · \(accent.title)"
        case .widgetDefaults:
            "الخلفية والخط والأرقام"
        case .calendar:
            "تصحيح الهجري: \(offsetLabel)"
        case .about:
            "الإصدار \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
        }
    }

    @ViewBuilder
    private func destination(_ page: SettingsPage) -> some View {
        switch page {
        case .occasions:
            OccasionsView()
        case .finance:
            FinanceSettingsView()
        case .health:
            HealthSettingsPage()
        default:
            ScrollView {
                VStack(spacing: 20) {
                    switch page {
                    case .prayer: PrayerSettingsSection()
                    case .counter: counterSection
                    case .appearance: appearanceSection
                    case .widgetDefaults: widgetDefaultsSection
                    case .calendar: calendarSection
                    case .about, .occasions, .finance, .health: aboutSection
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(page.title)
            .navigationBarTitleDisplayMode(.inline)
        }
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

    // MARK: العدّاد والتنبيهات
    private var counterSection: some View {
        SettingsSection("عدّاد الذكر") {
            Toggle("اهتزاز عند العدّ داخل التطبيق", isOn: $haptics)
            Button(role: .destructive) { showResetCounter = true } label: {
                Label("تصفير عدّاد اليوم", systemImage: "arrow.counterclockwise")
            }
            .confirmationDialog("تصفير عدد اليوم لكل الأذكار؟", isPresented: $showResetCounter, titleVisibility: .visible) {
                Button("تصفير", role: .destructive) {
                    TasbeehCounter.resetToday()
                    WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.istighfar.rawValue)
                }
            }
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
    }

    // MARK: التقويم
    private var calendarSection: some View {
        SettingsSection("التقويم") {
            SettingRow("تصحيح التاريخ الهجري", detail: offsetLabel) {
                HStack {
                    Text(DateHelper.hijriDayMonth(.now) + " " + DateHelper.hijriYear(.now) + " هـ")
                        .font(AppFont.uiBold(16))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Stepper("تصحيح التاريخ الهجري", value: $hijriOffset, in: -2...2)
                        .labelsHidden()
                }
            }
            Text("حسب تقويم أم القرى. إذا اختلف إعلان رؤية الهلال، زِد أو أنقص يوماً، ويتعدّل التاريخ وعدّاد رمضان والعيد.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
            Divider()
            SettingRow("بداية الأسبوع") {
                Picker("بداية الأسبوع", selection: $weekStart) {
                    Text("السبت").tag(7)
                    Text("الأحد").tag(1)
                    Text("الاثنين").tag(2)
                }
                .pickerStyle(.segmented)
            }
        }
        .onChange(of: hijriOffset) { WidgetCenter.shared.reloadAllTimelines() }
        .onChange(of: weekStart) { WidgetCenter.shared.reloadAllTimelines() }
    }

    private var offsetLabel: String {
        switch hijriOffset {
        case 0: "بدون تصحيح"
        case let days where days > 0: "+\(DateHelper.arabic(days)) يوم"
        default: "−\(DateHelper.arabic(-hijriOffset)) يوم"
        }
    }

    // MARK: عن التطبيق
    private var aboutSection: some View {
        SettingsSection("عن التطبيق") {
            HStack {
                Text("الإصدار")
                Spacer()
                Text(AppLinks.version)
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack {
                Text("الموقع")
                Spacer()
                Link("kaebs19.github.io", destination: AppLinks.site)
                    .environment(\.layoutDirection, .leftToRight)
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

// MARK: - أقسام الإعدادات
enum SettingsPage: Hashable {
    case prayer, health, occasions, finance, counter, appearance, widgetDefaults, calendar, about

    var title: String {
        switch self {
        case .prayer:         "أوقات الصلاة"
        case .occasions:      "مناسباتي"
        case .finance:        "المال والأعمال"
        case .health:         "الصحة"
        case .counter:        "عدّاد الذكر"
        case .appearance:     "المظهر"
        case .widgetDefaults: "الشكل الافتراضي للودجات"
        case .calendar:       "التقويم"
        case .about:          "عن التطبيق"
        }
    }

    var symbol: String {
        switch self {
        case .prayer:         "moon.stars.fill"
        case .occasions:      "birthday.cake.fill"
        case .finance:        "banknote.fill"
        case .health:         "heart.fill"
        case .counter:        "circle.dotted.circle"
        case .appearance:     "paintpalette.fill"
        case .widgetDefaults: "square.on.square.fill"
        case .calendar:       "calendar"
        case .about:          "info.circle.fill"
        }
    }

    /// لون مربع الأيقونة، على طريقة إعدادات iOS
    var color: Color {
        switch self {
        case .prayer:         Color(red: 0.11, green: 0.49, blue: 0.33)
        case .occasions:      Color(red: 0.85, green: 0.36, blue: 0.47)
        case .finance:        Color(red: 0.16, green: 0.60, blue: 0.40)
        case .health:         Color(red: 1.0, green: 0.22, blue: 0.37)
        case .counter:        Color(red: 0.55, green: 0.42, blue: 0.85)
        case .appearance:     Color(red: 0.93, green: 0.58, blue: 0.20)
        case .widgetDefaults: Color(red: 0.25, green: 0.52, blue: 0.90)
        case .calendar:       Color(red: 0.88, green: 0.30, blue: 0.27)
        case .about:          Color(white: 0.55)
        }
    }
}
