//
//  AppIcon.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

/// أيقونة من SF Symbols أو من أيقوناتنا المخصصة في SharedAssets.
enum AppIcon {
    case system(String)
    case asset(ImageResource)
}

/// أيقونات SF تتبع حجم الخط تلقائياً، أما المخصصة فصور لا تتأثر بالخط،
/// فنعطيها `size` يقارب ارتفاع الأيقونة عند ذلك الخط.
struct AppIconView: View {
    let icon: AppIcon
    let size: CGFloat

    var body: some View {
        switch icon {
        case .system(let name):
            Image(systemName: name)
        case .asset(let resource):
            Image(resource)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
}
