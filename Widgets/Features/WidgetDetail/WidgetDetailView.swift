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
    /// الذكر المعروض في معاينة ودجت العدّاد (في الشاشة الرئيسية يُختار من «تعديل الودجت»)
    @State private var tasbeeh: TasbeehDhikr = .istighfar

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
            // يُرسم بمقاس الودجت الحقيقي ثم يُصغَّر كاملاً، فالمعاينة تطابق الشاشة الرئيسية
            // ولا يُقص نص (آية طويلة مثلاً) لأن المساحة أصغر من الودجت
            GeometryReader { proxy in
                WidgetPreviewView(kind: kind, size: size, style: style, tasbeeh: tasbeeh)
                    .frame(width: size.size.width, height: size.size.height)
                    .cardStyle(radius: 24)
                    .scaleEffect(proxy.size.width / size.size.width)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .aspectRatio(size.aspectRatio, contentMode: .fit)
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

                    if kind == .istighfar {
                        SettingsSection("الذكر") {
                            ChoiceChips(options: TasbeehDhikr.allCases, selection: $tasbeeh) { dhikr in
                                Text(dhikr.isLong ? "\(dhikr.title) · \(dhikr.goal == 1 ? "مرة" : "١٠٠")" : dhikr.title)
                                    .font(AppFont.ui(14))
                            }
                            Text("كل ذكر له عدده اليومي. لتغيير الذكر في الشاشة الرئيسية: اضغط مطولاً على الودجت ثم «تعديل الودجت».")
                                .font(AppFont.ui(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
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
