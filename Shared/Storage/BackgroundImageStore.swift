//
//  BackgroundImageStore.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import UIKit

/// صور الخلفيات التي يختارها المستخدم، محفوظة في المساحة المشتركة ليقرأها الـ Widget.
/// تُصغّر قبل الحفظ: ذاكرة الـ Widget محدودة، وأكبر ودجت ما يحتاج أكثر من ١٢٠٠ نقطة ضوئية.
nonisolated enum BackgroundImageStore {
    private static let maxPixels: CGFloat = 1200

    private static var folder: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id)?
            .appendingPathComponent("Backgrounds", isDirectory: true)
    }

    private static func url(for id: String) -> URL? {
        folder?.appendingPathComponent("\(id).jpg")
    }

    /// يحفظ الصورة ويرجع معرّفها، أو nil إذا تعذّر الحفظ
    static func save(_ image: UIImage) -> String? {
        guard let folder else { return nil }
        let id = UUID().uuidString
        let scale = min(1, maxPixels / max(image.size.width * image.scale, image.size.height * image.scale))
        let size = CGSize(width: image.size.width * image.scale * scale,
                          height: image.size.height * image.scale * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let data = resized.jpegData(compressionQuality: 0.8), let url = url(for: id) else { return nil }
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
            return id
        } catch {
            return nil
        }
    }

    static func image(for id: String) -> UIImage? {
        url(for: id).flatMap { UIImage(contentsOfFile: $0.path) }
    }

    /// يحذف الصور التي لم يعد يستخدمها أي شكل محفوظ
    static func removeUnused(keeping ids: Set<String>) {
        guard let folder,
              let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        else { return }
        for file in files where !ids.contains(file.deletingPathExtension().lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
