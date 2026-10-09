//
//  SupportLinks.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SafariServices
import SwiftUI
import UIKit

// MARK: - روابط الدعم
// الصفحات القانونية والأسئلة على الموقع، فتُعدَّل بدون تحديث التطبيق
enum AppLinks {
    static let site = URL(string: "https://kaebs19.github.io/Widget-Website/")!
    static let faq = URL(string: "https://kaebs19.github.io/Widget-Website/#faq")!
    static let privacy = URL(string: "https://kaebs19.github.io/Widget-Website/privacy.html")!
    static let terms = URL(string: "https://kaebs19.github.io/Widget-Website/terms.html")!
    static let x = URL(string: "https://x.com/B_c_Arab")!
    static let supportEmail = "kaebs19@gmail.com"

    // MARK: App Store
    static let appStoreID = "6820719175"
    /// صفحة التطبيق في App Store، للمشاركة
    static let appStore = URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    /// يفتح App Store مباشرة على نافذة كتابة التقييم
    static let writeReview = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return "\(short) (\(build))"
    }

    /// رسالة بريد جاهزة فيها إصدار التطبيق والجهاز، لتسهيل تتبع المشكلة
    static func mail(subject: String, body: String = "") -> URL? {
        let device = UIDevice.current
        let footer = "\n\n—\nالتطبيق: \(version)\nالجهاز: \(device.model) · iOS \(device.systemVersion)"
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = supportEmail
        parts.queryItems = [URLQueryItem(name: "subject", value: subject),
                            URLQueryItem(name: "body", value: body + footer)]
        return parts.url
    }
}

// MARK: - متصفح داخل التطبيق
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(Theme.gold)
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - المصادر والتراخيص
struct CreditsView: View {
    private struct Credit: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let license: String
    }

    private let credits: [Credit] = [
        Credit(title: "نص القرآن الكريم وخطه",
               detail: "مجمع الملك فهد لطباعة المصحف الشريف، رواية حفص، الإصدار ٣٠. النص كما هو دون أي تعديل.",
               license: "شروط استخدام مجمع الملك فهد"),
        Credit(title: "الأذكار", detail: "من كتاب حصن المسلم.", license: "—"),
        Credit(title: "حساب مواقيت الصلاة والقبلة", detail: "مكتبة Adhan من Batoul Apps.", license: "MIT"),
        Credit(title: "خط أميري (Amiri)", detail: "Khaled Hosny.", license: "SIL Open Font License 1.1"),
        Credit(title: "خط الرقعة (Aref Ruqaa)", detail: "The Aref Ruqaa Project Authors.", license: "SIL Open Font License 1.1"),
        Credit(title: "خطا القاهرة وتجوال (Cairo, Tajawal)", detail: "من Google Fonts.", license: "SIL Open Font License 1.1"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(credits) { credit in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(credit.title).font(AppFont.uiBold(16))
                        Text(credit.detail)
                            .font(AppFont.ui(14))
                            .foregroundStyle(Theme.textSecondary)
                        Text(credit.license)
                            .font(AppFont.ui(12))
                            .foregroundStyle(Theme.gold)
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Theme.cardTop.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                Text("جزى الله خيرًا كل من ساهم في هذه الأعمال.")
                    .font(AppFont.ui(13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("المصادر والتراخيص")
        .navigationBarTitleDisplayMode(.inline)
    }
}
