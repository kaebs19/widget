import SwiftUI

// Only the background and date dependencies are replaced; typography sources are compiled unchanged.
nonisolated enum WidgetBackground: Codable, Hashable, Sendable { case preset(BackgroundPreset) }
nonisolated enum BackgroundPreset: String, Codable, Sendable {
    case night
    var textColor: Color.Resolved { .init(red: 1, green: 1, blue: 1) }
    var accentColor: Color.Resolved { .init(red: 0.9, green: 0.7, blue: 0.4) }
}
nonisolated enum DateHelper {
    static func arabic(_ value: Int) -> String { String(value) }
}
