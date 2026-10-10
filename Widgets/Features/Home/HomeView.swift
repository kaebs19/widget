//
//  HomeView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = GalleryViewModel()
    @State private var showHowTo = false
    @State private var showSettings = false
    /// يتغيّر بعد إغلاق الإعدادات فتُرسم المعاينات من جديد (الموقع، التقويم، الشكل الافتراضي)
    @State private var refresh = 0
    @Environment(WidgetStyleStore.self) private var styleStore
    @Environment(\.scenePhase) private var scenePhase

    // عمودين متساويين للودجات الصغيرة
    private let smallGrid = [GridItem(.flexible(), spacing: 14),
                             GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    CategoryBar(selected: viewModel.selectedCategory,
                                onSelect: viewModel.select,
                                showsInstalled: viewModel.showsInstalled)

                    if viewModel.showsInstalled {
                        installedHeader
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
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .id(refresh)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("ويدجت")
            .toolbar {
                // الإعدادات و«ودجاتي» في الجهة المقابلة لزر طريقة الإضافة
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("الإعدادات")
                    Button { viewModel.toggleInstalled() } label: {
                        Image(systemName: viewModel.showsInstalled ? "square.stack.3d.up.fill" : "square.stack.3d.up")
                    }
                    .accessibilityLabel("ودجاتي")
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showHowTo = true } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("طريقة الإضافة")
                }
            }
            .navigationDestination(for: WidgetKind.self) { kind in
                WidgetDetailView(kind: kind)
            }
            // النظام لا يخبرنا عند إضافة ودجت، فنقرأ القائمة عند كل عودة للتطبيق
            .task { await viewModel.loadInstalled() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await viewModel.loadInstalled() } }
            }
            .sheet(isPresented: $showHowTo) { HowToAddView().appAppearance() }
            .fullScreenCover(isPresented: $showSettings, onDismiss: { refresh += 1 }) { SettingsView().environment(styleStore).appAppearance() }
        }
    }

    /// عنوان «ودجاتي»، أو شرح الإضافة إذا لم يُضف شيء بعد
    @ViewBuilder
    private var installedHeader: some View {
        let count = viewModel.installedCount
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("ودجاتي")
                    .font(AppFont.uiBold(22))
                    .foregroundStyle(Theme.textPrimary)
                if count > 0 {
                    Text("\(DateHelper.arabic(count)) ودجت")
                        .font(AppFont.ui(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Button("كل الودجات") { viewModel.toggleInstalled() }
                    .font(AppFont.uiBold(14))
            }
            Text(count > 0
                 ? "الودجات التي أضفتها لشاشتك الرئيسية وشاشة القفل. اضغط أي ودجت لتخصيصه."
                 : "ما أضفت أي ودجت لشاشتك بعد. اختر ودجت من المعرض ثم أضفه من الشاشة الرئيسية.")
                .font(AppFont.ui(13))
                .foregroundStyle(Theme.textSecondary)
            if count == 0 {
                Button { showHowTo = true } label: {
                    Label("طريقة الإضافة", systemImage: "questionmark.circle")
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
                    Text("\(DateHelper.arabic(widgets.small.count + widgets.wide.count)) ودجت")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.bottom, 2)

            ForEach(widgets.wide) { kind in
                GalleryCard(kind: kind, installed: installedInfo(kind))
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
