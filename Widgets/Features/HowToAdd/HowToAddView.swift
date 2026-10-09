//
//  HowToAddView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

struct HowToAddView: View {
    @Environment(\.dismiss) private var dismiss

    /// مكان الإضافة: الشاشة الرئيسية أو شاشة القفل
    enum Place: String, CaseIterable, Identifiable {
        case home, lock
        var id: Self { self }
        var title: String { self == .home ? "الشاشة الرئيسية" : "شاشة القفل" }
    }

    @State private var place: Place = .home

    // الخطوات كبيانات، والـ View يعرضها بحلقة. لو تبي تعدل خطوة، تعدل النص بس
    private var steps: [(icon: String, text: String)] {
        switch place {
        case .home: [
            ("hand.tap", "اضغط مطولاً على مكان فاضي في الشاشة الرئيسية"),
            ("plus.circle", "اضغط زر «تعديل» ثم «إضافة ودجت» أعلى الشاشة"),
            ("magnifyingglass", "ابحث عن «ويدجت» واختره من القائمة"),
            ("rectangle.split.3x1", "اسحب يمين ويسار لاختيار الودجت والحجم"),
            ("checkmark.circle", "اضغط «إضافة ودجت» وبعدها «تم»"),
            ("slider.horizontal.3", "لتغيير الذكر أو المناسبة أو النمط: اضغط مطولاً على الودجت ثم «تعديل الودجت»"),
        ]
        case .lock: [
            ("lock", "افتح الجوال بوجهك أو رمزك، وابقَ على شاشة القفل"),
            ("hand.tap", "اضغط مطولاً على شاشة القفل ثم «تخصيص»"),
            ("iphone", "اختر «شاشة القفل»"),
            ("square.dashed", "اضغط مكان الودجات تحت الساعة، أو السطر فوقها"),
            ("moon.stars", "اختر من «ويدجت»: الصلاة القادمة أو التاريخ الهجري أو عداد الذكر"),
            ("checkmark.circle", "اضغط «تم» لحفظ شاشة القفل"),
        ]
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("المكان", selection: $place.animation(.snappy)) {
                    ForEach(Place.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 14) {
                        Text(DateHelper.arabic(index + 1))
                            .font(AppFont.uiBold(15))
                            .foregroundStyle(Theme.onAccent)
                            .frame(width: 30, height: 30)
                            .background(Theme.gold, in: Circle())
                        Text(step.text)
                            .font(AppFont.ui(15))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Image(systemName: step.icon)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Theme.cardTop)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("طريقة الإضافة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }.tint(Theme.gold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
