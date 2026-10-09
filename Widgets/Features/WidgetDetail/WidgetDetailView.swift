//
//  WidgetDetailView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// المعاينة وتحتها التخصيص مباشرة. التعديلات تظهر في المعاينة، ولا تُحفظ إلا بزر ✓.
struct WidgetDetailView: View {
    let kind: WidgetKind
    @Environment(WidgetStyleStore.self) private var styles
    @Environment(\.dismiss) private var dismiss
    @State private var size: WidgetSize
    /// التعديلات غير المحفوظة؛ nil تعني الشكل المحفوظ كما هو
    @State private var draft: WidgetStyle?
    @State private var showHowTo = false
    @State private var showDiscard = false

    init(kind: WidgetKind) {
        self.kind = kind
        // نبدأ بالحجم اللي ظهر في المعرض
        _size = State(initialValue: kind.previewSize)
    }

    private var saved: WidgetStyle { styles.style(for: kind) }
    private var style: WidgetStyle { draft ?? saved }
    private var hasChanges: Bool { draft.map { $0 != saved } ?? false }

    private var styleBinding: Binding<WidgetStyle> {
        Binding(get: { style }, set: { draft = $0 })
    }

    private var preview: some View {
        VStack(spacing: 12) {
            // الصغير بعرض ثابت، والباقي يملأ العرض.
            // النسبة قبل تحديد العرض، وإلا يأخذ الصغير ارتفاع عرض الشاشة كاملاً
            WidgetPreviewView(kind: kind, size: size, style: style)
                .aspectRatio(size.aspectRatio, contentMode: .fit)
                .cardStyle(radius: 24)
                .frame(maxWidth: size == .small ? 170 : .infinity, maxHeight: 200)
                .animation(.snappy, value: size)
                .animation(.snappy, value: style)

            if kind.supportedSizes.count > 1 {
                Picker("الحجم", selection: $size) {
                    ForEach(kind.supportedSizes, id: \.self) { s in
                        Text(s.title).tag(s)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding([.horizontal, .top], 16)
        .padding(.bottom, 8)
    }

    var body: some View {
        VStack(spacing: 0) {
            // المعاينة ثابتة أعلى الصفحة، فتشوف أثر كل تعديل وأنت تمرّر الخيارات
            preview
            ScrollView {
                VStack(spacing: 20) {
                    Text(kind.subtitle)
                        .font(AppFont.ui(14))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if kind == .specialOccasion {
                        ReminderPermissionView()
                    }

                    WidgetCustomizeView(kind: kind, style: styleBinding)
                }
                .padding(16)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        // فيه تعديلات غير محفوظة: زر رجوع يسأل قبل ما تضيع
        .navigationBarBackButtonHidden(hasChanges)
        .toolbar {
            if hasChanges {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showDiscard = true } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .accessibilityLabel("رجوع")
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showHowTo = true } label: {
                    Image(systemName: "questionmark.circle")
                }
                .accessibilityLabel("طريقة إضافة الودجت")
                Button {
                    styles.save(style, for: [kind])
                    draft = nil
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(!hasChanges)
                .accessibilityLabel("حفظ")
            }
        }
        .tint(Theme.gold)
        .confirmationDialog("عندك تعديلات ما حفظتها", isPresented: $showDiscard, titleVisibility: .visible) {
            Button("حفظ والرجوع") {
                styles.save(style, for: [kind])
                dismiss()
            }
            Button("تجاهل التعديلات", role: .destructive) { dismiss() }
        }
        .sheet(isPresented: $showHowTo) { HowToAddView() }
    }
}
