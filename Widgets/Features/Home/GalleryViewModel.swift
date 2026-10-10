//
//  GalleryViewModel.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import Observation
import WidgetKit

/// ودجت أضافه المستخدم لشاشته: النوع، وكم نسخة، وأين (الرئيسية أو القفل)
struct InstalledWidget: Identifiable, Hashable {
    let kind: WidgetKind
    let count: Int
    let families: [WidgetFamily]

    var id: WidgetKind { kind }

    /// «صغير ×٢ · قفل»
    var detail: String {
        var parts: [String] = []
        let sizes: [(WidgetSize, [WidgetFamily])] = [(.small, [.systemSmall]), (.medium, [.systemMedium]),
                                                      (.large, [.systemLarge, .systemExtraLarge])]
        for (size, matching) in sizes {
            let n = families.filter(matching.contains).count
            if n > 0 { parts.append(n > 1 ? "\(size.title) ×\(DateHelper.arabic(n))" : size.title) }
        }
        if families.contains(where: \.isLockScreen) { parts.append("قفل") }
        return parts.joined(separator: " · ")
    }
}

// الـ ViewModel يقرر "وش يُعرض"، والـ View يقرر "كيف يُعرض".
// كذا الـ View يبقى بسيط، والمنطق تقدر تختبره بدون واجهة.
@Observable
final class GalleryViewModel {

    /// القسم المختار. nil = الكل
    var selectedCategory: WidgetCategory? = nil

    /// «ودجاتي»: يعرض المضافة فقط
    var showsInstalled = false

    /// الودجات المضافة على الشاشة الرئيسية وشاشة القفل، بترتيب المعرض
    private(set) var installed: [InstalledWidget] = []

    /// يقرأ من النظام الودجات المضافة. يُستدعى عند فتح التطبيق والرجوع إليه.
    @MainActor
    func loadInstalled() async {
        let infos = (try? await WidgetCenter.shared.currentConfigurations()) ?? []
        let grouped = Dictionary(grouping: infos.compactMap { info in
            WidgetKind(rawValue: info.kind).map { ($0, info.family) }
        }, by: \.0)
        let result = WidgetKind.allCases.compactMap { kind -> InstalledWidget? in
            guard let items = grouped[kind] else { return nil }
            return InstalledWidget(kind: kind, count: items.count, families: items.map(\.1))
        }
        withAnimation(.snappy) {
            installed = result
            if result.isEmpty { showsInstalled = false }
        }
    }

    /// الودجات المضافة في قسم معيّن
    func installed(in category: WidgetCategory) -> [InstalledWidget] {
        installed.filter { $0.kind.category == category }
    }

    /// الأقسام اللي تظهر حسب الفلتر
    var visibleCategories: [WidgetCategory] {
        if showsInstalled {
            return WidgetCategory.allCases.filter { !installed(in: $0).isEmpty }
        }
        if let selectedCategory { return [selectedCategory] }
        return WidgetCategory.allCases
    }

    /// ودجات قسم معيّن، مقسومة لصغيرة (شبكة عمودين) وكبيرة (عرض كامل)
    func widgets(in category: WidgetCategory) -> (small: [WidgetKind], wide: [WidgetKind]) {
        let items = showsInstalled ? installed(in: category).map(\.kind)
                                   : WidgetKind.allCases.filter { $0.category == category }
        return (items.filter { $0.previewSize == .small },
                items.filter { $0.previewSize != .small })
    }

    func select(_ category: WidgetCategory?) {
        withAnimation(.snappy) {
            showsInstalled = false
            selectedCategory = category
        }
    }

    func selectInstalled() {
        withAnimation(.snappy) {
            showsInstalled = true
            selectedCategory = nil
        }
    }
}
