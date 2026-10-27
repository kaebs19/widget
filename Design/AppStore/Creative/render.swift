// صور «الرأس» و«نتائج البحث» لصفحة المتجر (App Store Connect › Product Page Information).
// التشغيل من جذر المشروع:  swift Design/AppStore/Creative/render.swift
// المخرجات بلا شفافية وبالمقاس المطلوب بالضبط في Design/AppStore/Upload/Creative/

import AppKit
import CoreText
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let store = root.appendingPathComponent("Design/AppStore")
let output = store.appendingPathComponent("Upload/Creative")

// MARK: - الهوية (من شاشة البداية وصور المتجر الحالية)
let gold = Color(red: 0xE9 / 255, green: 0xC9 / 255, blue: 0x8A / 255)
let text = Color(red: 0xF3 / 255, green: 0xF0 / 255, blue: 0xEA / 255)
let muted = Color(red: 0x9C / 255, green: 0x97 / 255, blue: 0x8E / 255)

for weight in ["Regular", "Medium", "SemiBold", "Bold"] {
    let url = root.appendingPathComponent("Shared/Resources/Fonts/IBMPlexSansArabic-\(weight).ttf")
    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
}

func plex(_ size: CGFloat, _ weight: String = "Bold") -> Font { .custom("IBMPlexSansArabic-\(weight)", size: size) }

func image(_ path: String) -> NSImage {
    guard let image = NSImage(contentsOf: store.appendingPathComponent(path)) ??
            NSImage(contentsOf: root.appendingPathComponent(path)) else { fatalError("missing \(path)") }
    return image
}

// MARK: - الخلفية: داكنة بلمعة خفيفة، وهلال ونجوم هندسية باهتة كما في صور المتجر
struct Backdrop: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                LinearGradient(colors: [Color(red: 0.07, green: 0.09, blue: 0.08), Color(red: 0.035, green: 0.04, blue: 0.04)],
                               startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [gold.opacity(0.10), .clear], center: .init(x: 0.5, y: 0.35),
                               startRadius: 0, endRadius: size.width * 0.45)
                Crescent()
                    .stroke(gold.opacity(0.10), lineWidth: 6)
                    .frame(width: size.height * 0.62, height: size.height * 0.62)
                    .position(x: size.width * 0.88, y: size.height * 0.12)
                Crescent()
                    .stroke(gold.opacity(0.06), lineWidth: 5)
                    .frame(width: size.height * 0.4, height: size.height * 0.4)
                    .rotationEffect(.degrees(180))
                    .position(x: size.width * 0.08, y: size.height * 0.86)
                ForEach(0..<6, id: \.self) { index in
                    Octagram()
                        .stroke(Color.white.opacity(0.035), lineWidth: 3)
                        .frame(width: size.height * 0.28, height: size.height * 0.28)
                        .position(x: size.width * [0.12, 0.3, 0.7, 0.9, 0.22, 0.78][index],
                                  y: size.height * [0.22, 0.9, 0.08, 0.7, 0.55, 0.42][index])
                }
            }
        }
    }
}

struct Crescent: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = rect.width / 2
        let c = CGPoint(x: rect.midX, y: rect.midY)
        // قوس خارجي ثم قوس داخلي مزاح، يكوّنان هلالاً
        path.addArc(center: c, radius: r, startAngle: .degrees(-60), endAngle: .degrees(200), clockwise: false)
        path.addArc(center: CGPoint(x: c.x + r * 0.32, y: c.y - r * 0.22), radius: r * 0.82,
                    startAngle: .degrees(205), endAngle: .degrees(-65), clockwise: true)
        path.closeSubpath()
        return path
    }
}

struct Octagram: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for angle in [0.0, 45.0] {
            path.addPath(Rectangle().path(in: rect.insetBy(dx: rect.width * 0.15, dy: rect.height * 0.15))
                .applying(CGAffineTransform(translationX: -rect.midX, y: -rect.midY)
                    .concatenating(CGAffineTransform(rotationAngle: angle * .pi / 180))
                    .concatenating(CGAffineTransform(translationX: rect.midX, y: rect.midY))))
        }
        return path
    }
}

// MARK: - الأجهزة
struct Phone: View {
    let screen: String
    let width: CGFloat

    var body: some View {
        let bezel = width * 0.034
        let screenWidth = width - bezel * 2
        Image(nsImage: image(screen))
            .resizable()
            .aspectRatio(1320.0 / 2868.0, contentMode: .fit)
            .frame(width: screenWidth)
            .clipShape(RoundedRectangle(cornerRadius: screenWidth * 0.135, style: .continuous))
            .overlay(alignment: .top) {
                Capsule().fill(Color.black)
                    .frame(width: screenWidth * 0.31, height: screenWidth * 0.09)
                    .padding(.top, screenWidth * 0.025)
            }
            .padding(bezel)
            .background(Color(red: 0.11, green: 0.11, blue: 0.12),
                        in: RoundedRectangle(cornerRadius: width * 0.155, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: width * 0.155, style: .continuous)
                .strokeBorder(Color(white: 0.28), lineWidth: width * 0.006))
            .shadow(color: .black.opacity(0.6), radius: width * 0.08, y: width * 0.05)
    }
}

struct Watch: View {
    let screen: String
    let width: CGFloat

    var body: some View {
        let bezel = width * 0.07
        let screenWidth = width - bezel * 2
        VStack(spacing: 0) {
            // السوار من أعلى وأسفل يوحي بالساعة دون تفاصيل كثيرة
            RoundedRectangle(cornerRadius: width * 0.12).fill(Color(white: 0.09))
                .frame(width: width * 0.72, height: width * 0.32)
            Image(nsImage: image(screen))
                .resizable()
                .aspectRatio(416.0 / 496.0, contentMode: .fit)
                .frame(width: screenWidth)
                .clipShape(RoundedRectangle(cornerRadius: screenWidth * 0.22, style: .continuous))
                .padding(bezel)
                .background(Color(red: 0.11, green: 0.11, blue: 0.12),
                            in: RoundedRectangle(cornerRadius: width * 0.27, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: width * 0.27, style: .continuous)
                    .strokeBorder(Color(white: 0.3), lineWidth: width * 0.01))
                .overlay(alignment: .trailing) {
                    RoundedRectangle(cornerRadius: width * 0.03).fill(Color(white: 0.22))
                        .frame(width: width * 0.06, height: width * 0.2)
                        .offset(x: width * 0.045, y: -width * 0.12)
                }
            RoundedRectangle(cornerRadius: width * 0.12).fill(Color(white: 0.09))
                .frame(width: width * 0.72, height: width * 0.32)
        }
        .shadow(color: .black.opacity(0.6), radius: width * 0.1, y: width * 0.06)
    }
}

// MARK: - النصوص لكل لغة
// تطابق اسم التطبيق وعبارته في المتجر (metadata-ar.md) وشاشة البداية
struct Copy {
    let code: String
    let direction: LayoutDirection
    let name: String
    let header: (before: String, highlight: String, after: String)
    let headerSubtitle: String
    let search: (before: String, highlight: String, after: String)
    let searchSubtitle: String
    /// العربية أعرض حروفاً بالحجم نفسه، فالإنجليزية تأخذ حجماً أصغر لتبقى في المنطقة الآمنة
    let headerSize: CGFloat
    let searchSize: CGFloat

    static let arabic = Copy(
        code: "ar", direction: .rightToLeft, name: "ويدجت",
        header: ("كل ما تحتاجه في ", "لمحة", ""),
        headerSubtitle: "ودجات الصلاة والأذكار والتقويم لشاشتك وساعتك",
        search: ("ودجات عربية ", "أنيقة", ""),
        searchSubtitle: "مواقيت الصلاة · الأذكار · التقويم الهجري · المناسبات",
        headerSize: 185, searchSize: 200)

    static let english = Copy(
        code: "en", direction: .leftToRight, name: "Widget",
        // الإنجليزية أعرض، فالعنوان على سطرين حتى يبقى داخل المنطقة الآمنة
        header: ("Everything you need\nat a ", "glance", ""),
        headerSubtitle: "Prayer, adhkar & calendar widgets",
        search: ("Beautiful ", "Arabic", " widgets"),
        searchSubtitle: "Prayer times · Adhkar · Hijri calendar · Occasions",
        headerSize: 140, searchSize: 190)
}

// MARK: - العلامة والعنوان
struct Brand: View {
    let copy: Copy
    let iconSize: CGFloat

    var body: some View {
        HStack(spacing: iconSize * 0.3) {
            Image(nsImage: image("Widgets/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"))
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.225, style: .continuous))
            Text(copy.name)
                .font(plex(iconSize * 0.62))
                .foregroundStyle(text)
        }
        .environment(\.layoutDirection, copy.direction)
    }
}

/// عنوان بكلمة ذهبية
func headline(_ parts: (before: String, highlight: String, after: String), size: CGFloat, direction: LayoutDirection) -> some View {
    Text("\(Text(parts.before).foregroundStyle(text))\(Text(parts.highlight).foregroundStyle(gold))\(Text(parts.after).foregroundStyle(text))")
        .font(plex(size))
        .multilineTextAlignment(.center)
        .lineSpacing(size * 0.05)
        .environment(\.layoutDirection, direction)
}

// MARK: - الرأس 3840×1646
struct Header: View {
    let copy: Copy

    var body: some View {
        ZStack {
            Backdrop()
            // الأجهزة على الجانبين خارج المنطقة الآمنة؛ لو قُصّت الصورة يبقى النص كاملاً
            Phone(screen: "iPhone/01-gallery.png", width: 640)
                .rotationEffect(.degrees(-9))
                .position(x: 620, y: 1000)
            Watch(screen: "Watch/01-prayer.png", width: 520)
                .rotationEffect(.degrees(8))
                .position(x: 3180, y: 830)
            VStack(spacing: copy.header.before.contains("\n") ? 44 : 70) {
                Brand(copy: copy, iconSize: copy.header.before.contains("\n") ? 140 : 170)
                headline(copy.header, size: copy.headerSize, direction: copy.direction)
                Text(copy.headerSubtitle)
                    .font(plex(78, "Medium"))
                    .foregroundStyle(muted)
                    .environment(\.layoutDirection, copy.direction)
            }
            .position(x: 1920, y: 823)
        }
        .frame(width: 3840, height: 1646)
        .clipped()
    }
}

// MARK: - نتائج البحث 3840×2560
struct SearchResult: View {
    let copy: Copy

    var body: some View {
        ZStack {
            Backdrop()
            VStack(spacing: 50) {
                Brand(copy: copy, iconSize: 150)
                headline(copy.search, size: copy.searchSize, direction: copy.direction)
                Text(copy.searchSubtitle)
                    .font(plex(80, "Medium"))
                    .foregroundStyle(muted)
                    .environment(\.layoutDirection, copy.direction)
            }
            .position(x: 1920, y: 470)
            Phone(screen: "iPhone/05-calendar.png", width: 700)
                .rotationEffect(.degrees(-6))
                .position(x: 1120, y: 1900)
            Phone(screen: "iPhone/03-finance.png", width: 700)
                .rotationEffect(.degrees(6))
                .position(x: 2720, y: 1900)
            Phone(screen: "iPhone/01-gallery.png", width: 820)
                .position(x: 1920, y: 1830)
            Watch(screen: "Watch/03-tasbeeh.png", width: 430)
                .rotationEffect(.degrees(-8))
                .position(x: 3420, y: 1150)
        }
        .frame(width: 3840, height: 2560)
        .clipped()
    }
}

// MARK: - التصدير بلا قناة شفافية
@MainActor
func export<V: View>(_ view: V, size: CGSize, name: String) {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    guard let rendered = renderer.cgImage else { fatalError("render failed \(name)") }
    let width = Int(size.width), height = Int(size.height)
    guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError() }
    context.setFillColor(CGColor(red: 0.04, green: 0.045, blue: 0.045, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.draw(rendered, in: CGRect(x: 0, y: 0, width: width, height: height))
    let url = output.appendingPathComponent(name)
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
    print("wrote \(url.path) \(width)x\(height)")
}

try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
MainActor.assumeIsolated {
    for copy in [Copy.arabic, .english] {
        export(Header(copy: copy), size: CGSize(width: 3840, height: 1646), name: "header-\(copy.code)-3840x1646.png")
        export(SearchResult(copy: copy), size: CGSize(width: 3840, height: 2560), name: "search-\(copy.code)-3840x2560.png")
    }
}
