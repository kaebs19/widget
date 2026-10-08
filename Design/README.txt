ويدجت — حزمة الأصول

Icons-SVG/              11 أيقونة مخصصة، شبكة 24×24، خط 1.5
Calligraphy-SVG/        أسماء الأيام (7) والأشهر الهجرية (12) والميلادية (12) بخط Aref Ruqaa Bold، محوّلة لمسارات
App-Icon/               AppIcon-1024.png — 1024×1024، RGB بدون شفافية وبدون زوايا (iOS يقصّها)
Widget-Designs-PNG/     25 ودجت @3x بخلفية شفافة — مرجع للبرمجة فقط
App-Store-Screenshots/  6.9 إنش 1320×2868 — 4 صور

إعداد ملفات SVG في Xcode (Assets.xcassets):
1. اسحب الملف إلى Assets
2. Render As: Template Image  ← عشان تتلون بالكود
3. فعّل Preserve Vector Data
4. Scales: Single Scale

الاستخدام في SwiftUI:
Image("icon-mosque").foregroundStyle(.white)
Image("day-1-sunday").resizable().scaledToFit().frame(height: 44).foregroundStyle(.white)

ملاحظة: كل ملفات الخط لها نفس الارتفاع ونفس خط الأساس،
فإذا أعطيتها نفس الـ frame height تطلع الحروف بنفس الحجم.
