//
//  HowToAddView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

struct HowToAddView: View {
    @Environment(\.dismiss) private var dismiss

    // الخطوات كبيانات، والـ View يعرضها بحلقة. لو تبي تعدل خطوة، تعدل النص بس
    private let steps: [(icon: String, text: String)] = [
        ("hand.tap", "اضغط مطولاً على مكان فاضي في الشاشة الرئيسية"),
        ("plus.circle", "اضغط زر «تعديل» ثم «إضافة ودجت» أعلى الشاشة"),
        ("magnifyingglass", "ابحث عن «ويدجت» واختره من القائمة"),
        ("rectangle.split.3x1", "اسحب يمين ويسار لاختيار الودجت والحجم"),
        ("checkmark.circle", "اضغط «إضافة ودجت» وبعدها «تم»")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 14) {
                        Text(DateHelper.arabic(index + 1))
                            .font(AppFont.uiBold(15))
                            .foregroundStyle(.black)
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
