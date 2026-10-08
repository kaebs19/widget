//
//  GalleryViewModel.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import Observation

// الـ ViewModel يقرر "وش يُعرض"، والـ View يقرر "كيف يُعرض".
// كذا الـ View يبقى بسيط، والمنطق تقدر تختبره بدون واجهة.
@Observable
final class GalleryViewModel {

    /// القسم المختار. nil = الكل
    var selectedCategory: WidgetCategory? = nil

    /// الأقسام اللي تظهر حسب الفلتر
    var visibleCategories: [WidgetCategory] {
        if let selectedCategory { return [selectedCategory] }
        return WidgetCategory.allCases
    }

    /// ودجات قسم معيّن، مقسومة لصغيرة (شبكة عمودين) وكبيرة (عرض كامل)
    func widgets(in category: WidgetCategory) -> (small: [WidgetKind], wide: [WidgetKind]) {
        let items = WidgetKind.allCases.filter { $0.category == category }
        return (items.filter { $0.previewSize == .small },
                items.filter { $0.previewSize != .small })
    }

    func select(_ category: WidgetCategory?) {
        withAnimation(.snappy) { selectedCategory = category }
    }
}
