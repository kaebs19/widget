//
//  AppGroup.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Foundation

/// مساحة مشتركة بين التطبيق والـ Widget. نفس المعرّف لازم يكون في ملفّي الـ entitlements.
nonisolated enum AppGroup {
    static let id = "group.com.widgetar.app"

    /// نسخة واحدة للتطبيق كله: @AppStorage يراقب التغييرات على نفس النسخة اللي يكتب فيها الزر
    static let defaults = UserDefaults(suiteName: id) ?? .standard
}
