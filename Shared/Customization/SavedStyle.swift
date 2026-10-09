//
//  SavedStyle.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents

// MARK: - نمط محفوظ
// شكل له اسم يحفظه المستخدم من التطبيق، ثم يختاره لأي ودجت من «تعديل الودجت»،
// فيصير لكل نسخة في الشاشة الرئيسية شكلها حتى لو كانت من نفس النوع.
nonisolated struct SavedStyle: Codable, Hashable, Identifiable, Sendable {
    var id = UUID()
    var name: String
    var style: WidgetStyle
}

// MARK: - الربط مع «تعديل الودجت»
nonisolated struct SavedStyleEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "نمط"
    static let defaultQuery = SavedStyleQuery()

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

    init(_ saved: SavedStyle) {
        id = saved.id
        name = saved.name
    }
}

nonisolated struct SavedStyleQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [SavedStyleEntity] {
        WidgetStyleStorage.savedStyles().filter { identifiers.contains($0.id) }.map(SavedStyleEntity.init)
    }

    func suggestedEntities() async throws -> [SavedStyleEntity] {
        WidgetStyleStorage.savedStyles().map(SavedStyleEntity.init)
    }
}
