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

                    ForEach(viewModel.visibleCategories) { category in
                        section(category)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("ويدجت")
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("الإعدادات")
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
            .sheet(isPresented: $showSettings) { SettingsView().environment(styleStore).appAppearance() }
        }
    }

    // MARK: - قسم
    @ViewBuilder
    private func section(_ category: WidgetCategory) -> some View {
        let widgets = viewModel.widgets(in: category)

        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text(category.title)
            } icon: {
                AppIconView(icon: category.icon, size: 22)
            }
                .font(AppFont.uiBold(20))
                .foregroundStyle(Theme.textPrimary)

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
