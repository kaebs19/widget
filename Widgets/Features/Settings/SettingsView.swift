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
    @AppStorage(AppLanguage.preferenceKey, store: AppGroup.defaults) private var language = AppLanguage.system
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
    @AppStorage(AppSettings.Key.numerals, store: AppGroup.defaults) private var numerals = Numerals.latin

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    generalGroup
                    group(L10n.text("المحتوى")) {
                        NavigationLink {
                            ScrollView { WeatherSettingsView().padding(16).readableWidth() }
                                .background(Theme.background.ignoresSafeArea())
                                .navigationTitle(L10n.text("الطقس"))
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            rowLabel(L10n.text("الطقس"), WeatherLocation.saved?.city ?? L10n.text("اختر موقع الطقس"),
                                     symbol: "cloud.sun.fill", color: Color(red: 0.18, green: 0.52, blue: 0.85), chevron: true)
                        }
                        .buttonStyle(.plain)
                        row(.prayer)
                        #if !targetEnvironment(macCatalyst)
                        row(.health)
                        #endif
                        row(.occasions)
                        row(.finance)
                        row(.counter)
                    }
                    group(L10n.text("الدعم")) {
                        actionRow(L10n.text("طريقة الإضافة"), L10n.text("للشاشة الرئيسية وشاشة القفل"), symbol: "questionmark.circle.fill",
                                  color: Color(red: 0.20, green: 0.60, blue: 0.86), chevron: true) { showHowTo = true }
                        actionRow(L10n.text("الأسئلة الشائعة"), L10n.text("إجابات سريعة لأكثر الأسئلة"), symbol: "bubble.left.and.text.bubble.right.fill",
                                  color: Color(red: 0.36, green: 0.42, blue: 0.86), external: true) { webPage = AppLinks.faq }
                        actionRow(L10n.text("تواصل معنا"), AppLinks.supportEmail, symbol: "envelope.fill",
                                  color: Color(red: 0.18, green: 0.62, blue: 0.52), external: true) {
                            if let url = AppLinks.mail(subject: L10n.text("دعم تطبيق ويدجت")) { openURL(url) }
                        }
                        actionRow(L10n.text("إبلاغ عن خطأ في نص"), L10n.text("آية أو ذكر يحتاج تصحيح"), symbol: "exclamationmark.bubble.fill",
                                  color: Color(red: 0.90, green: 0.45, blue: 0.20), external: true) {
                            if let url = AppLinks.mail(subject: L10n.text("خطأ في نص"),
                                                       body: "اسم الودجت:\nالنص الذي فيه الخطأ:\nالتصحيح المقترح:\n") {
                                openURL(url)
                            }
                        }
                        actionRow(L10n.text("قيّم التطبيق"), L10n.text("رأيك يساعدنا نتحسّن"), symbol: "star.fill",
                                  color: Color(red: 0.95, green: 0.70, blue: 0.15), external: true) { openURL(AppLinks.writeReview) }
                        ShareLink(item: AppLinks.appStore,
                                  message: Text(L10n.text("جرّب تطبيق ويدجت: ودجات الصلاة والأذكار والتقويم الهجري"))) {
                            rowLabel(L10n.text("شارك التطبيق"), L10n.text("أرسله لمن تحب"), symbol: "square.and.arrow.up.fill",
                                     color: Color(red: 0.55, green: 0.42, blue: 0.85))
                        }
                        .buttonStyle(.plain)
                        actionRow(L10n.text("تابعنا على X"), "@B_c_Arab", symbol: "at",
                                  color: Color(white: 0.2), external: true) { openURL(AppLinks.x) }
                    }
                    group(L10n.text("عن التطبيق")) {
                        row(.about)
                        actionRow(L10n.text("سياسة الخصوصية"), L10n.text("كيف نتعامل مع بياناتك"), symbol: "hand.raised.fill",
                                  color: Color(red: 0.25, green: 0.52, blue: 0.90), external: true) { webPage = AppLinks.privacy }
                        actionRow(L10n.text("شروط الاستخدام"), L10n.text("شروط استخدام التطبيق"), symbol: "doc.text.fill",
                                  color: Color(white: 0.5), external: true) { webPage = AppLinks.terms }
                        NavigationLink { CreditsView() } label: {
                            rowLabel(L10n.text("المصادر والتراخيص"), L10n.text("مصادر النصوص والخطوط والمكتبات"), symbol: "books.vertical.fill",
                                     color: Color(red: 0.62, green: 0.48, blue: 0.30), chevron: true)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("\(L10n.text("ويدجت")) \(AppLinks.version)")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(16)
                .readableWidth()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(L10n.text("الإعدادات"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text("تم")) { dismiss() }
                }
            }
            .navigationDestination(for: SettingsPage.self) { page in
                destination(page)
            }
            .sheet(isPresented: $showHowTo) { HowToAddView().appAppearance() }
            #if targetEnvironment(macCatalyst)
            // على الماك تُفتح الصفحات في المتصفح، فهو المعتاد هناك
            .onChange(of: webPage) { _, url in
                if let url { openURL(url) }
                webPage = nil
            }
            #else
            .sheet(item: $webPage) { url in SafariView(url: url).ignoresSafeArea() }
            #endif
        }
        .tint(Theme.accent(accent))
    }

    // MARK: الإعدادات العامة
    // أول ما يراه المستخدم: ما يُختار مرة ويشمل التطبيق والودجات كلها، والسريع منه يتغيّر في مكانه
    private var generalGroup: some View {
        group(L10n.text("الإعدادات العامة")) {
            NavigationLink {
                LanguageSettingsView()
            } label: {
                rowLabel(L10n.text("اللغة"), language.title,
                         symbol: "globe", color: Color(red: 0.28, green: 0.46, blue: 0.88),
                         chevron: true)
            }
            .buttonStyle(.plain)
            controlRow(L10n.text("الأرقام"), symbol: "number", color: Color(red: 0.36, green: 0.42, blue: 0.86)) {
                Picker(L10n.text("الأرقام"), selection: numeralsBinding) {
                    Text("123").tag(Numerals.latin)
                    Text("١٢٣").tag(Numerals.arabic)
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
            }
            controlRow(L10n.text("الثيم"), symbol: "circle.lefthalf.filled", color: Color(white: 0.35)) {
                Picker(L10n.text("الثيم"), selection: $colorScheme) {
                    Text(ColorSchemeChoice.dark.title).tag(ColorSchemeChoice.dark)
                    Text(ColorSchemeChoice.light.title).tag(ColorSchemeChoice.light)
                    Text(L10n.text("تلقائي")).tag(ColorSchemeChoice.system)
                }
                .pickerStyle(.segmented)
                .frame(width: 190)
            }
            controlRow(L10n.text("لون التطبيق"), symbol: "paintpalette.fill", color: Color(red: 0.93, green: 0.58, blue: 0.20)) {
                HStack(spacing: 8) {
                    ForEach(AppAccent.allCases) { option in
                        AccentSwatch(accent: option, isSelected: option == accent, size: 24) {
                            withAnimation(.snappy) { accent = option }
                        }
                    }
                }
            }
            row(.location)
            row(.notifications)
            row(.widgetDefaults)
            row(.calendar)
            controlRow(L10n.text("الاهتزاز"), symbol: "iphone.radiowaves.left.and.right", color: Color(red: 0.55, green: 0.42, blue: 0.85)) {
                Toggle(L10n.text("الاهتزاز"), isOn: $haptics).labelsHidden()
            }
        }
    }

    /// الأرقام تشمل كل الودجات حتى المخصّصة، فالتغيير يمر من المتجر
    private var numeralsBinding: Binding<Numerals> {
        Binding(get: { numerals }, set: { styles.applyNumerals($0) })
    }

    /// سطر فيه عنصر تحكم مباشر بدل فتح صفحة
    private func controlRow<Control: View>(_ title: String, symbol: String, color: Color,
                                           @ViewBuilder control: () -> Control) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(title)
                .font(AppFont.uiBold(15))
                .lineLimit(1)
                .fixedSize()
            Spacer(minLength: 8)
            control()
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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
                Image(systemName: language.isRightToLeft ? "chevron.left" : "chevron.right")
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
                Image(systemName: external ? (language.isRightToLeft ? "arrow.up.left" : "arrow.up.right") : (language.isRightToLeft ? "chevron.left" : "chevron.right"))
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
            OccasionStore.all().isEmpty ? L10n.text("أعياد الميلاد والذكريات") : "\(DateHelper.arabic(OccasionStore.all().count)) مناسبة"
        case .health:
            HealthCache.isConnected
                ? HealthCache.load().map { "\(HealthMetric.steps.format($0.value(.steps))) خطوة اليوم" } ?? L10n.text("مربوط بتطبيق الصحة")
                : L10n.text("الخطوات والسعرات والنوم")
        case .finance:
            Payday.allCases.map { $0.cycle() }.min { $0.next < $1.next }
                .map { "\($0.payday.displayName) \(PaydayFormat.remaining($0.days))" } ?? ""
        case .counter:
            haptics ? L10n.text("الاهتزاز مفعّل") : L10n.text("الاهتزاز متوقف")
        case .location:
            PrayerLocation.saved?.city ?? L10n.text("مكة المكرمة (افتراضي)")
        case .notifications:
            PrayerNotifications.isEnabled ? L10n.text("تنبيه الأذان مفعّل") : L10n.text("الأذان والتذكيرات")
        case .widgetDefaults:
            L10n.text("الخلفية والخط للودجات")
        case .calendar:
            "\(L10n.text("تصحيح التاريخ الهجري")): \(offsetLabel)"
        case .about:
            "\(L10n.text("الإصدار")) \(AppLinks.version)"
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
        case .notifications:
            NotificationSettingsPage()
                .navigationTitle(page.title)
                .navigationBarTitleDisplayMode(.inline)
        default:
            ScrollView {
                VStack(spacing: 20) {
                    switch page {
                    case .prayer: PrayerSettingsSection()
                    case .counter: counterSection
                    case .location: locationSection
                    case .widgetDefaults: widgetDefaultsSection
                    case .calendar: calendarSection
                    case .about, .occasions, .finance, .health, .notifications: aboutSection
                    }
                }
                .padding(16)
                .readableWidth()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(page.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: الموقع
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PrayerLocationSettings()
            Text(L10n.text("موقعك يحسب أوقات الصلاة واتجاه القبلة، ويبقى على جهازك ولا يُشارك مع أحد."))
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 6)
        }
    }

    // MARK: افتراضيات الودجات
    private var defaultStyle: Binding<WidgetStyle> {
        Binding(get: { styles.defaultStyle }, set: { styles.saveDefault($0) })
    }

    private var widgetDefaultsSection: some View {
        VStack(spacing: 20) {
            SettingsSection(L10n.text("معاينة الشكل الافتراضي")) {
                WidgetPreviewView(kind: .morningDhikr, size: .medium, style: styles.defaultStyle)
                    .aspectRatio(WidgetSize.medium.aspectRatio, contentMode: .fit)
                    .cardStyle(radius: 20)
                    .animation(.snappy, value: styles.defaultStyle)
                Text(L10n.text("تُحفظ التغييرات تلقائيًا للودجات التي لم تخصصها. الودجات المخصصة تبقى على شكلها حتى تطبق الإعدادات على الكل."))
                    .font(AppFont.ui(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            TypographySettingsSection(style: defaultStyle)
            SettingsSection(L10n.text("الخلفية")) {
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
            SettingsSection(L10n.text("أسماء التقويم")) {
                Toggle(L10n.text("أسماء الأيام والأشهر بالخط العربي المصوّر"), isOn: defaultStyle.usesCalligraphy)
                    .font(AppFont.ui(14))
                Text(L10n.text("أوقف الخط المصوّر لعرض أسماء التقويم بالخط الذي تختاره."))
                    .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
            }
            Button { showResetAll = true } label: {
                Label(L10n.text("تطبيق على كل الودجات"), systemImage: "square.on.square")
                    .font(AppFont.uiBold(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            }
            .confirmationDialog(L10n.text("إلغاء تخصيص كل الودجات؟"), isPresented: $showResetAll, titleVisibility: .visible) {
                Button(L10n.text("تطبيق الشكل الافتراضي على الكل"), role: .destructive) { styles.resetAllToDefault() }
            } message: {
                Text(L10n.text("كل ودجت خصّصته يرجع للشكل الافتراضي. أنماطك المحفوظة تبقى."))
            }
        }
    }

    // MARK: العدّاد والتنبيهات
    private var counterSection: some View {
        SettingsSection(L10n.text("عدّاد الذكر")) {
            Toggle(L10n.text("اهتزاز عند العدّ داخل التطبيق"), isOn: $haptics)
            Button(role: .destructive) { showResetCounter = true } label: {
                Label(L10n.text("تصفير عدّاد اليوم"), systemImage: "arrow.counterclockwise")
            }
            .confirmationDialog(L10n.text("تصفير عدد اليوم لكل الأذكار؟"), isPresented: $showResetCounter, titleVisibility: .visible) {
                Button(L10n.text("تصفير"), role: .destructive) {
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
        SettingsSection(L10n.text("التقويم")) {
            SettingRow(L10n.text("تصحيح التاريخ الهجري"), detail: offsetLabel) {
                HStack {
                    Text(DateHelper.hijriDayMonth(.now) + " " + DateHelper.hijriYear(.now) + " هـ")
                        .font(AppFont.uiBold(16))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Stepper(L10n.text("تصحيح التاريخ الهجري"), value: $hijriOffset, in: -2...2)
                        .labelsHidden()
                }
            }
            Text(L10n.text("حسب تقويم أم القرى. إذا اختلف إعلان رؤية الهلال، زِد أو أنقص يوماً، ويتعدّل التاريخ وعدّاد رمضان والعيد."))
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
            Divider()
            SettingRow(L10n.text("بداية الأسبوع")) {
                Picker(L10n.text("بداية الأسبوع"), selection: $weekStart) {
                    Text(L10n.text("السبت")).tag(7)
                    Text(L10n.text("الأحد")).tag(1)
                    Text(L10n.text("الاثنين")).tag(2)
                }
                .pickerStyle(.segmented)
            }
        }
        .onChange(of: hijriOffset) { WidgetCenter.shared.reloadAllTimelines() }
        .onChange(of: weekStart) { WidgetCenter.shared.reloadAllTimelines() }
    }

    private var offsetLabel: String {
        switch hijriOffset {
        case 0: L10n.text("بدون تصحيح")
        case let days where days > 0: "+\(DateHelper.arabic(days)) يوم"
        default: "−\(DateHelper.arabic(-hijriOffset)) يوم"
        }
    }

    // MARK: عن التطبيق
    private var aboutSection: some View {
        SettingsSection(L10n.text("عن التطبيق")) {
            HStack {
                Text(L10n.text("الإصدار"))
                Spacer()
                Text(AppLinks.version)
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack {
                Text(L10n.text("الموقع الإلكتروني"))
                Spacer()
                Link("kaebs19.github.io", destination: AppLinks.site)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Text(L10n.text("نص القرآن الكريم وخطه من مجمع الملك فهد لطباعة المصحف الشريف."))
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
    }
}

// MARK: - Language selection
private struct LanguageSettingsView: View {
    @AppStorage(AppLanguage.preferenceKey, store: AppGroup.defaults) private var language = AppLanguage.system

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(spacing: 0) {
                    ForEach(AppLanguage.allCases) { option in
                        if option != .system {
                            Divider().padding(.horizontal, 16)
                        }
                        Button {
                            language = option
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: option == .system ? "iphone" : "globe")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.gold)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.title)
                                        .font(AppFont.uiBold(16))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text(subtitle(for: option))
                                        .font(AppFont.ui(13))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: language == option ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(language == option ? Theme.gold : Theme.textSecondary.opacity(0.4))
                            }
                            .padding(16)
                            .frame(minHeight: 72)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(language == option ? .isSelected : [])
                    }
                }
                .background(Theme.cardTop.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text(L10n.text("تتغير لغة الواجهة واتجاهها مباشرةً حسب اختيارك."))
                    .font(AppFont.ui(13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 6)
            }
            .padding(16)
            .readableWidth()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(L10n.text("لغة التطبيق"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: language) { _, _ in
            WidgetCenter.shared.reloadAllTimelines()
            Task { await PrayerNotifications.reschedule() }
        }
    }

    private func subtitle(for option: AppLanguage) -> String {
        switch option {
        case .system: L10n.text("استخدام لغة الجهاز تلقائيًا")
        case .arabic: "Arabic"
        case .english: "الإنجليزية"
        }
    }
}

// MARK: - دائرة لون التطبيق
private struct AccentSwatch: View {
    let accent: AppAccent
    let isSelected: Bool
    var size: CGFloat = 34
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let hex = colorScheme == .light ? accent.hex.light : accent.hex.dark
        Button(action: action) {
            Circle()
                .fill(Color(Color.Resolved(hex: hex)))
                .frame(width: size, height: size)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: size * 0.38, weight: .bold))
                            .foregroundStyle(colorScheme == .light ? .white : .black)
                    }
                }
                .overlay(Circle().strokeBorder(Theme.textPrimary.opacity(isSelected ? 0.8 : 0), lineWidth: 2).padding(-size * 0.12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accent.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - أقسام الإعدادات
enum SettingsPage: Hashable {
    case prayer, health, occasions, finance, counter, location, notifications, widgetDefaults, calendar, about

    var title: String {
        switch self {
        case .prayer:         L10n.text("أوقات الصلاة")
        case .occasions:      L10n.text("مناسباتي")
        case .finance:        L10n.text("المال والأعمال")
        case .health:         L10n.text("الصحة")
        case .counter:        L10n.text("عدّاد الذكر")
        case .location:       L10n.text("الموقع")
        case .notifications:  L10n.text("الإشعارات")
        case .widgetDefaults: L10n.text("الشكل العام")
        case .calendar:       L10n.text("التقويم")
        case .about:          L10n.text("عن التطبيق")
        }
    }

    var symbol: String {
        switch self {
        case .prayer:         "moon.stars.fill"
        case .occasions:      "birthday.cake.fill"
        case .finance:        "banknote.fill"
        case .health:         "heart.fill"
        case .counter:        "circle.dotted.circle"
        case .location:       "location.fill"
        case .notifications:  "bell.badge.fill"
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
        case .location:       Color(red: 0.20, green: 0.55, blue: 0.95)
        case .notifications:  Color(red: 0.92, green: 0.30, blue: 0.30)
        case .widgetDefaults: Color(red: 0.25, green: 0.52, blue: 0.90)
        case .calendar:       Color(red: 0.88, green: 0.30, blue: 0.27)
        case .about:          Color(white: 0.55)
        }
    }
}
