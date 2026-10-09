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
    @Environment(WidgetStyleStore.self) private var styleStore

    // عمودين متساويين للودجات الصغيرة
    private let smallGrid = [GridItem(.flexible(), spacing: 14),
                             GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    CategoryBar(selected: viewModel.selectedCategory,
                                onSelect: viewModel.select)

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
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("ويدجت")
            .toolbar {
                // الإعدادات في الجهة المقابلة لزر طريقة الإضافة
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("الإعدادات")
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
            .sheet(isPresented: $showHowTo) { HowToAddView().appAppearance() }
            .fullScreenCover(isPresented: $showSettings) { SettingsView().environment(styleStore).appAppearance() }
        }
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
                GalleryCard(kind: kind)
            }

            if !widgets.small.isEmpty {
                LazyVGrid(columns: smallGrid, spacing: 14) {
                    ForEach(widgets.small) { kind in
                        GalleryCard(kind: kind)
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
