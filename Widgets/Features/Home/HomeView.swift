//
//  HomeView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

struct HomeView: View {
    @AppStorage(AppLanguage.preferenceKey, store: AppGroup.defaults) private var language = AppLanguage.system
    @State private var viewModel = GalleryViewModel()
    @State private var navigationPath: [WidgetKind] = {
        #if DEBUG
        // فتح معاينة محددة في فحوص الواجهة ولقطات التطوير فقط.
        if let raw = UserDefaults.standard.string(forKey: "screenshotWidget"),
           let kind = WidgetKind(rawValue: raw) { return [kind] }
        #endif
        return []
    }()
    @State private var healthRoute: HealthRoute? = {
        #if DEBUG
        if let metric = UserDefaults.standard.string(forKey: "screenshotHealthMetric"),
           let url = URL(string: "widgetar://health/" + metric) { return HealthRoute(url: url) }
        #endif
        return nil
    }()
    @State private var showHowTo = false
    @State private var showPaywall = false
    @Environment(StoreManager.self) private var store
    @State private var showSettings = false
    @State private var showsSearch = false
    @FocusState private var searchFocused: Bool
    /// يتغيّر بعد إغلاق الإعدادات فتُرسم المعاينات من جديد (الموقع، التقويم، الشكل الافتراضي)
    @State private var refresh = 0
    @Environment(WidgetStyleStore.self) private var styleStore
    @Environment(\.scenePhase) private var scenePhase

    @Environment(\.horizontalSizeClass) private var sizeClass

    /// الآيباد والماك: أعمدة بقدر ما يتسع العرض. الآيفون: عمودان للصغيرة، والعريضة بعرض كامل.
    private var isWide: Bool { sizeClass == .regular }

    private var smallGrid: [GridItem] {
        isWide ? [GridItem(.adaptive(minimum: 170), spacing: 18, alignment: .top)]
               : [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]
    }

    private var wideGrid: [GridItem] {
        // عمودان يملآن العرض: أغلب الأقسام فيها ودجتان عريضتان، فلا يبقى عمود ثالث فارغ على الماك
        isWide ? Array(repeating: GridItem(.flexible(), spacing: 18, alignment: .top), count: 2) : [GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    CategoryBar(selected: viewModel.selectedCategory,
                                onSelect: viewModel.select,
                                showsInstalled: viewModel.showsInstalled)

                    if viewModel.showsInstalled {
                        installedHeader
                    }

                    if !viewModel.hasResults {
                        ContentUnavailableView {
                            Label(L10n.text("لا توجد نتائج"), systemImage: "magnifyingglass")
                        } description: {
                            Text(L10n.text("جرّب كلمة أخرى أو اختر قسمًا مختلفًا."))
                        }
                    }

                    ForEach(Array(viewModel.visibleCategories.enumerated()), id: \.element) { index, category in
                        if index > 0 {
                            // فاصل واضح بين الأقسام
                            Rectangle()
                                .fill(Theme.border)
                                .frame(height: 1)
                                .padding(.vertical, 4)
                        }
                        section(category)
                    }
                }
                .padding(.horizontal, isWide ? 28 : 16)
                .padding(.bottom, 32)
                // على الشاشات العريضة جداً لا تتمدد البطاقات بلا حد
                .frame(maxWidth: 1200)
                .frame(maxWidth: .infinity)
                .id("\(refresh)|\(language.rawValue)")
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(L10n.text("ويدجت"))
            .safeAreaInset(edge: .top, spacing: 0) {
                if showsSearch { searchBar }
            }
            .toolbar {
                // الإعدادات و«ودجاتي» في الجهة المقابلة لزر طريقة الإضافة
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showsSearch.toggle()
                        searchFocused = showsSearch
                        if !showsSearch { viewModel.searchText = "" }
                    } label: {
                        Label(L10n.text("ابحث عن ودجت"), systemImage: "magnifyingglass")
                    }
                    .accessibilityValue(showsSearch ? L10n.text("مفتوح") : L10n.text("مغلق"))
                    Button { viewModel.toggleInstalled() } label: {
                        Label(L10n.text("ودجاتي"), systemImage: viewModel.showsInstalled ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                    }
                }
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Label(L10n.text("الإعدادات"), systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showHowTo = true } label: {
                        Label(L10n.text("طريقة الإضافة"), systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationDestination(for: WidgetKind.self) { kind in
                WidgetDetailView(kind: kind)
            }
            // النظام لا يخبرنا عند إضافة ودجت، فنقرأ القائمة عند كل عودة للتطبيق
            .task { await viewModel.loadInstalled() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refresh += 1; Task { await viewModel.loadInstalled() } }
            }
            .onOpenURL { url in
                if url.scheme == "widgetar", url.host == "premium" {
                    showPaywall = true
                    return
                }
                if url.scheme == "widgetar", url.host == "weather" {
                    navigationPath = [.weather]
                    return
                }
                guard let route = HealthRoute(url: url) else { return }
                healthRoute = route
            }
            .sheet(item: $healthRoute) { route in
                NavigationStack {
                    Group {
                        if let metric = route.metric { HealthMetricDetailView(metric: metric) }
                        else if route.page == "water" { WaterTrackingView() }
                        else if route.page == "weekly" { HealthInsightsPage(mode: .weekly) }
                        else if route.page == "streak" { HealthInsightsPage(mode: .streak) }
                        else if route.page == "workouts" { HealthInsightsPage(mode: .workouts) }
                        else { HealthSettingsPage() }
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button(L10n.text("إغلاق"), systemImage: "xmark") { healthRoute = nil } }
                    }
                }
                .appAppearance()
            }
            .sheet(isPresented: $showHowTo) { HowToAddView().appAppearance() }
            .sheet(isPresented: $showPaywall) { PaywallView().environment(store).environment(styleStore).appAppearance() }
            .fullScreenCover(isPresented: $showSettings, onDismiss: { refresh += 1 }) { SettingsView().environment(styleStore).environment(store).appAppearance() }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.textSecondary)
                TextField(L10n.text("ابحث عن ودجت"), text: $viewModel.searchText)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .onSubmit { searchFocused = false }
                if !viewModel.searchText.isEmpty {
                    Button { viewModel.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .accessibilityLabel(L10n.text("مسح البحث"))
                }
            }
            .padding(12)
            .background(Theme.cardTop, in: RoundedRectangle(cornerRadius: 14))
            Button(L10n.text("إلغاء")) {
                searchFocused = false
                showsSearch = false
                viewModel.searchText = ""
            }
        }
        .font(AppFont.ui(15))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.background)
        .onAppear { searchFocused = true }
    }

    /// عنوان «ودجاتي»، أو شرح الإضافة إذا لم يُضف شيء بعد
    @ViewBuilder
    private var installedHeader: some View {
        let count = viewModel.installedCount
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.text("ودجاتي"))
                    .font(AppFont.uiBold(22))
                    .foregroundStyle(Theme.textPrimary)
                if count > 0 {
                    Text(L10n.widgetCount(count))
                        .font(AppFont.ui(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button(L10n.text("كل الودجات")) { viewModel.toggleInstalled() }
                    .font(AppFont.uiBold(14))
            }
            Text(count > 0
                 ? L10n.text("الودجات التي أضفتها لشاشتك الرئيسية وشاشة القفل. اضغط أي ودجت لتخصيصه.")
                 : L10n.text("ما أضفت أي ودجت لشاشتك بعد. اختر ودجت من المعرض ثم أضفه من الشاشة الرئيسية."))
                .font(AppFont.ui(13))
                .foregroundStyle(Theme.textSecondary)
            if count == 0 {
                Button { showHowTo = true } label: {
                    Label(L10n.text("طريقة الإضافة"), systemImage: "questionmark.circle")
                        .font(AppFont.uiBold(15))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(Theme.onAccent)
                        .background(Theme.gold, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 4)
            }
        }
    }

    private func installedInfo(_ kind: WidgetKind) -> InstalledWidget? {
        viewModel.installed.first { $0.kind == kind }
    }

    // MARK: - قسم
    @ViewBuilder
    private func section(_ category: WidgetCategory) -> some View {
        let widgets = viewModel.widgets(in: category)

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                // صورة القسم داخل مربع ملوّن
                AppIconView(icon: category.icon, size: 26)
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 48, height: 48)
                    .background(Theme.gold.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.title)
                        .font(AppFont.uiBold(20))
                        .foregroundStyle(Theme.textPrimary)
                    Text(L10n.widgetCount(widgets.small.count + widgets.wide.count))
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.bottom, 2)

            if !widgets.wide.isEmpty {
                LazyVGrid(columns: wideGrid, alignment: .leading, spacing: 18) {
                    ForEach(widgets.wide) { kind in
                        GalleryCard(kind: kind, installed: installedInfo(kind))
                    }
                }
            }

            if !widgets.small.isEmpty {
                LazyVGrid(columns: smallGrid, spacing: 14) {
                    ForEach(widgets.small) { kind in
                        GalleryCard(kind: kind, installed: installedInfo(kind))
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(WidgetStyleStore())
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
}
