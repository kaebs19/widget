//
//  Ease.swift
//  Widgets
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import Foundation

// MARK: - التوقيت
// المشاهد المتحركة تُحسب من الزمن مباشرة كما في ملفات التصميم
nonisolated enum Ease {
    static func progress(_ t: Double, _ start: Double, _ duration: Double) -> Double {
        min(max((t - start) / duration, 0), 1)
    }

    static func enter(_ t: Double, _ start: Double, _ duration: Double) -> Double {
        1 - pow(1 - progress(t, start, duration), 3)
    }

    static func move(_ t: Double, _ start: Double, _ duration: Double) -> Double {
        let x = progress(t, start, duration)
        return x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
    }

    static func pop(_ t: Double, _ start: Double, _ duration: Double) -> Double {
        let x = progress(t, start, duration), c1 = 1.70158, c3 = c1 + 1
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    }
}
