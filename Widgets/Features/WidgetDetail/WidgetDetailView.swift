//
//  WidgetDetailView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

struct WidgetDetailView: View {
    let kind: WidgetKind
    @Environment(WidgetStyleStore.self) private var styles
    @State private var size: WidgetSize
    @State private var showHowTo = false
    @State private var showCustomize = false

    init(kind: WidgetKind) {
        self.kind = kind
        // نبدأ بالحجم اللي ظهر في المعرض
        _size = State(initialValue: kind.previewSize)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // المعاينة: الصغير بعرض ثابت، والباقي يملأ العرض.
                // النسبة قبل تحديد العرض، وإلا يأخذ الصغير ارتفاع عرض الشاشة كاملاً
                WidgetPreviewView(kind: kind, size: size, style: styles.style(for: kind))
                    .aspectRatio(size.aspectRatio, contentMode: .fit)
                    .cardStyle(radius: 28)
                    .frame(maxWidth: size == .small ? 200 : .infinity)
                    .animation(.snappy, value: size)

                if kind.supportedSizes.count > 1 {
                    Picker("الحجم", selection: $size) {
                        ForEach(kind.supportedSizes, id: \.self) { s in
                            Text(s.title).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(kind.title)
                        .font(AppFont.uiBold(22))
                        .foregroundStyle(Theme.textPrimary)
                    Text(kind.subtitle)
                        .font(AppFont.ui(15))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if kind == .specialOccasion {
                    ReminderPermissionView()
                }

                VStack(spacing: 12) {
                    Button { showCustomize = true } label: {
                        Label("تخصيص الشكل", systemImage: "paintbrush.pointed")
                            .font(AppFont.uiBold(16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.black)
                            .background(Theme.gold, in: RoundedRectangle(cornerRadius: 16))
                    }
                    Button { showHowTo = true } label: {
                        Label("طريقة إضافة الودجت", systemImage: "plus.square.on.square")
                            .font(AppFont.uiBold(16))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(Theme.gold)
                            .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showHowTo) { HowToAddView() }
        .sheet(isPresented: $showCustomize) {
            WidgetCustomizeView(kind: kind, style: styles.style(for: kind), size: size)
                .environment(styles)
        }
    }
}
