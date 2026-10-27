//
//  OnboardingView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import SwiftUI
import UserNotifications

// MARK: - التعريف بالتطبيق
// ثلاث صفحات بعد شاشة البداية أول مرة: الموقع، الإشعارات، عام. كل صفحة فيها معاينة حيّة تتجاوب مع الإعدادات.
struct OnboardingView: View {
    var logoNamespace: Namespace.ID
    var showsLogo = true
    let onFinish: () -> Void

    @Environment(WidgetStyleStore.self) private var styles
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppLanguage.preferenceKey, store: AppGroup.defaults) private var language = AppLanguage.system
    @AppStorage(AppSettings.Key.colorScheme, store: AppGroup.defaults) private var colorScheme = ColorSchemeChoice.dark
    @AppStorage(AppSettings.Key.numerals, store: AppGroup.defaults) private var numerals = Numerals.latin
    @AppStorage(PrayerSchedule.Key.method, store: AppGroup.defaults) private var method = PrayerMethod.ummAlQura

    @State private var page = 0
    /// يتحرك بين الصفحات بانسيابية، ومنه تُحسب الإزاحة والشفافية وامتلاء الخطوات
    @State private var progress = 0.0
    @State private var appeared = false
    @State private var locator = LocationProvider()
    @State private var autoLocation = false
    @State private var showCitySearch = false
    @State private var adhan = true
    @State private var prePrayer = false
    @State private var afterAdhkar = true
    @State private var digitsFlash = false
    /// ارتفاع المساحة المتاحة؛ الشاشات القصيرة (الشاشة الخارجية في iPhone Duo وiPhone SE) تأخذ معاينة أقصر
    @State private var availableHeight: CGFloat = 0

    private var previewHeight: CGFloat { availableHeight > 0 && availableHeight < 760 ? 150 : 190 }

    private var isRTL: Bool { layoutDirection == .rightToLeft }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 16)
            OBStepper(progress: progress)
                .padding(.top, 14)
                .opacity(appeared ? 1 : 0)
            ScrollView {
                ZStack(alignment: .top) {
                    ForEach(0..<3, id: \.self) { index in
                        pageContent(index)
                            .allowsHitTesting(index == page)
                            .accessibilityHidden(index != page)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            Button(action: next) {
                HStack(spacing: 6) {
                    Text(page < 2 ? L10n.text("التالي") : L10n.text("ابدأ الاستخدام"))
                    Image(systemName: isRTL ? "arrow.left" : "arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .buttonStyle(OBPrimaryButtonStyle())
            .padding(.bottom, 12)
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 568)
        .frame(maxWidth: .infinity)
        .background(OB.background.ignoresSafeArea())
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { availableHeight = $0 }
        .sheet(isPresented: $showCitySearch) {
            CitySearchView { found in
                found.save()
                PrayerWidgets.reload()
            }
            .appAppearance()
        }
        .onAppear {
            // الصفحة الأولى تدخل بعد وصول الشعار لمكانه
            withAnimation(OB.enter(reduceMotion ? 0.2 : 0.8).delay(reduceMotion ? 0 : 0.4)) { appeared = true }
        }
        .onChange(of: autoLocation) { _, on in
            if on { locator.locate() }
        }
        .onChange(of: locator.isDenied) { _, denied in
            // بدون إذن يرجع المفتاح مقفلاً، والمدينة تُختار يدوياً
            if denied { withAnimation(OB.move(0.25)) { autoLocation = false } }
        }
    }

    // MARK: الرأس
    private var header: some View {
        HStack(spacing: 10) {
            Group {
                if showsLogo {
                    WidgetLogo()
                        .frame(width: 32, height: 32)
                        .matchedGeometryEffect(id: "logo", in: logoNamespace)
                } else {
                    Color.clear.frame(width: 32, height: 32)
                }
            }
            Text(L10n.text("ويدجت"))
                .font(OB.font(21, .bold))
                .foregroundStyle(OB.text)
                .opacity(appeared ? 1 : 0)
            Spacer()
            Button(L10n.text("تخطي"), action: finish)
                .font(OB.font(15))
                .foregroundStyle(OB.muted)
                .opacity(appeared ? 1 : 0)
        }
        .frame(height: 32)
    }

    // MARK: الصفحات
    @ViewBuilder
    private func pageContent(_ index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                switch index {
                case 0: LocationPreview(state: locationState, location: locator.location)
                case 1: NotificationPreview(adhan: adhan, prePrayer: prePrayer, afterAdhkar: afterAdhkar)
                default: GeneralPreview(numerals: numerals, flash: digitsFlash)
                }
            }
            .frame(height: previewHeight)
            .frame(maxWidth: .infinity)
            .background(OB.panel, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(index == 2 && digitsFlash ? OB.accent.opacity(0.6) : OB.line, lineWidth: index == 2 && digitsFlash ? 2 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .modifier(PageShift(progress: progress, index: index, factor: 1.6, isRTL: isRTL, appear: appeared ? 1 : 0))

            pageText(index)
                .modifier(PageShift(progress: progress, index: index, factor: 1, isRTL: isRTL, appear: appeared ? 1 : 0))

            VStack(spacing: 0) {
                switch index {
                case 0: locationRows
                case 1: notificationRows
                default: generalRows
                }
            }
            .background(OB.panel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(OB.line, lineWidth: 1))
            .modifier(PageShift(progress: progress, index: index, factor: 1.3, isRTL: isRTL, appear: appeared ? 1 : 0))
        }
    }

    private func pageText(_ index: Int) -> some View {
        let copy: (step: String, title: String, body: String) = switch index {
        case 0: (L10n.text("الخطوة ١ من ٣"), L10n.text("حدّد موقعك"),
                 L10n.text("لحساب مواقيت الصلاة والطقس بدقة. يبقى موقعك على جهازك ولا يُشارك."))
        case 1: (L10n.text("الخطوة ٢ من ٣"), L10n.text("ابقَ على اطلاع"),
                 L10n.text("اختر التنبيهات التي تهمّك، وسنذكّرك في الوقت المناسب دون إزعاج."))
        default: (L10n.text("الخطوة ٣ من ٣"), L10n.text("اجعلها على طريقتك"),
                  L10n.text("تفضيلات تنطبق على جميع الودجات، وتقدر تغيّرها في أي وقت."))
        }
        return VStack(alignment: .leading, spacing: 0) {
            Text(DateHelper.digits(copy.step))
                .font(OB.font(14, .semibold))
                .foregroundStyle(OB.accent)
            Text(copy.title)
                .font(OB.font(30, .bold))
                .foregroundStyle(OB.text)
                .padding(.top, 6)
            Text(copy.body)
                .font(OB.font(15))
                .lineSpacing(5)
                .foregroundStyle(OB.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: ١. الموقع
    private var locationState: LocationPreview.State {
        if locator.isLocating { return .detecting }
        return locator.location == nil ? .idle : .found
    }

    @ViewBuilder
    private var locationRows: some View {
        OBRow(symbol: "location.circle", title: L10n.text("تحديد الموقع تلقائياً")) {
            OBToggle(isOn: $autoLocation)
        }
        OBRow(symbol: "building.2", title: L10n.text("المدينة")) {
            Button { showCitySearch = true } label: {
                HStack(spacing: 4) {
                    Text(cityLabel)
                        .font(OB.font(15, .medium))
                        .foregroundStyle(locationState == .found ? OB.text : OB.muted)
                        .lineLimit(1)
                    if locationState != .detecting {
                        Image(systemName: isRTL ? "chevron.left" : "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(OB.dim)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(locationState == .detecting)
        }
        OBRow(symbol: "function", title: L10n.text("طريقة الحساب"), isLast: locator.errorMessage == nil) {
            Menu {
                Picker(L10n.text("طريقة الحساب"), selection: $method) {
                    ForEach(PrayerMethod.allCases) { Text($0.title).tag($0) }
                }
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(OB.muted)
                    Text(method.title)
                        .font(OB.font(15, .medium))
                        .foregroundStyle(OB.text)
                        .lineLimit(1)
                }
                .environment(\.layoutDirection, .leftToRight)
            }
            .onChange(of: method) { PrayerWidgets.reload() }
        }
        if let error = locator.errorMessage {
            Text(error)
                .font(OB.font(13))
                .foregroundStyle(Color.red.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
    }

    private var cityLabel: String {
        switch locationState {
        case .idle: L10n.text("غير محدد")
        case .detecting: L10n.text("جارٍ التحديد…")
        case .found: locator.location?.city ?? ""
        }
    }

    // MARK: ٢. الإشعارات
    @ViewBuilder
    private var notificationRows: some View {
        OBRow(symbol: "bell.badge", title: L10n.text("الأذان عند دخول الوقت"), height: 52) {
            OBToggle(isOn: $adhan)
        }
        OBRow(symbol: "clock", title: DateHelper.digits(L10n.text("تذكير قبل الصلاة بـ١٠ دقائق")), height: 52) {
            OBToggle(isOn: $prePrayer)
        }
        OBRow(symbol: "book", title: L10n.text("أذكار بعد الصلاة"), height: 52, isLast: true) {
            OBToggle(isOn: $afterAdhkar)
        }
    }

    /// يُحفظ عند مغادرة الصفحة، والإذن يُطلب إن كان أي تنبيه مفعّلاً
    private func saveNotifications() {
        let defaults = AppGroup.defaults
        defaults.set(adhan || prePrayer, forKey: PrayerNotifications.Key.enabled)
        defaults.set(prePrayer ? 10 : 0, forKey: PrayerNotifications.Key.minutesBefore)
        defaults.set(afterAdhkar, forKey: PrayerNotifications.Key.afterAdhkar)
        guard adhan || prePrayer || afterAdhkar else { return }
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            await PrayerNotifications.reschedule()
        }
    }

    // MARK: ٣. عام
    @ViewBuilder
    private var generalRows: some View {
        OBRow(symbol: "character.bubble", title: L10n.text("اللغة"), height: 52) {
            OBSegmented(options: [("العربية", AppLanguage.arabic), ("English", AppLanguage.english)],
                        selection: languageBinding)
        }
        OBRow(symbol: "number", title: L10n.text("شكل الأرقام"), height: 52) {
            OBSegmented(options: [("123", Numerals.latin), ("١٢٣", Numerals.arabic)], selection: numeralsBinding)
        }
        OBRow(symbol: "moon", title: L10n.text("المظهر"), height: 52, isLast: true) {
            OBSegmented(options: [(ColorSchemeChoice.dark.title, ColorSchemeChoice.dark),
                                  (ColorSchemeChoice.light.title, .light),
                                  (L10n.text("تلقائي"), .system)],
                        selection: $colorScheme, width: 180)
        }
    }

    /// «لغة الجهاز» تظهر هنا باللغة التي تحلّ محلها
    private var languageBinding: Binding<AppLanguage> {
        Binding(get: { language.resolvedCode() == "en" ? .english : .arabic },
                set: { language = $0 })
    }

    /// الأرقام تتغير في كل التطبيق والودجات فوراً، وإطار المعاينة يومض بلون التمييز
    private var numeralsBinding: Binding<Numerals> {
        Binding(get: { numerals }, set: { value in
            guard value != numerals else { return }
            styles.applyNumerals(value)
            withAnimation(OB.enter(0.2)) { digitsFlash = true }
            withAnimation(OB.enter(0.8).delay(0.45)) { digitsFlash = false }
        })
    }

    // MARK: التنقل
    private func next() {
        if page == 1 { saveNotifications() }
        guard page < 2 else { return finish() }
        page += 1
        withAnimation(OB.move(reduceMotion ? 0.2 : 0.8)) { progress = Double(page) }
    }

    private func finish() {
        AppGroup.defaults.set(true, forKey: AppSettings.Key.onboardingCompleted)
        onFinish()
    }
}

// MARK: - إزاحة الصفحات
/// الصفحة التالية تدخل من نهاية السطر (اليسار في العربية) والسابقة تخرج لبدايته.
/// المعاينة تتحرك أسرع من النص والبطاقة، فيظهر عمق خفيف.
private struct PageShift: ViewModifier, Animatable {
    var progress: Double
    let index: Int
    let factor: Double
    let isRTL: Bool
    /// من ٠ إلى ١ عند الظهور الأول: الصفحة تنزلق ٣٠ نقطة لمكانها وتظهر
    var appear: Double

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(progress, appear) }
        set { progress = newValue.first; appear = newValue.second }
    }

    func body(content: Content) -> some View {
        let distance = Double(index) - progress
        let shift = distance * 60 * factor + (1 - appear) * 30
        content
            .opacity(max(0, 1 - abs(distance) * 2.2) * appear)
            .offset(x: isRTL ? -shift : shift)
    }
}
