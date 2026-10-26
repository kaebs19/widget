//
//  WatchTasbeehView.swift
//  WidgetsWatch
//
//  Created by Mohammed Saleh on 28/10/2026.
//

import SwiftUI
import WatchKit

// MARK: - عدّاد الذكر على الساعة
// الضغط في أي مكان يعدّ، والعدد يُرسل للآيفون فيتطابق مع ودجت العدّاد هناك.
struct WatchTasbeehView: View {
    @AppStorage("watch.tasbeeh.selected", store: AppGroup.defaults) private var dhikr = TasbeehDhikr.istighfar
    @State private var count = 0
    @State private var showsPicker = false
    @State private var showsReset = false

    private var reachedGoal: Bool { dhikr.goal.map { count >= $0 } ?? false }

    var body: some View {
        VStack(spacing: 6) {
            Text(dhikr.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(W.accent())
            Button(action: increment) {
                ring.contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(dhikr.text)، \(DateHelper.arabic(count))")
            Text(dhikr.text)
                .font(.system(size: dhikr.isLong ? 10 : 13, weight: .medium))
                .foregroundStyle(W.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                // الزر ملوّن بلون التمييز، فالأيقونة بلون النص فوقه
                Button { showsPicker = true } label: { Image(systemName: "list.bullet").foregroundStyle(W.onAccent) }
                    .accessibilityLabel(L10n.text("اختر الذكر"))
                Spacer()
                Button { showsReset = true } label: { Image(systemName: "arrow.counterclockwise").foregroundStyle(W.onAccent) }
                    .accessibilityLabel(L10n.text("تصفير عدّاد اليوم"))
            }
        }
        .sheet(isPresented: $showsPicker) { picker }
        .confirmationDialog(L10n.text("تصفير عدد اليوم لكل الأذكار؟"), isPresented: $showsReset) {
            Button(L10n.text("تصفير"), role: .destructive) {
                WatchSession.shared.resetTasbeehToday()
                refresh()
            }
        }
        .onAppear(perform: refresh)
        .onChange(of: dhikr) { refresh() }
        // عدد جديد وصل من الآيفون
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in refresh() }
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(W.ringTrack, lineWidth: 6)
            Circle()
                .trim(from: 0, to: dhikr.goal.map { min(Double(count) / Double($0), 1) } ?? 0)
                .stroke(W.accent(), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .environment(\.layoutDirection, .leftToRight)
                .animation(W.move(0.25), value: count)
            VStack(spacing: 0) {
                if reachedGoal {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(W.accent())
                }
                Text(DateHelper.arabic(count))
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(W.text)
                    .contentTransition(.numericText(value: Double(count)))
                    .animation(W.move(0.2), value: count)
                if let goal = dhikr.goal {
                    Text("/ \(DateHelper.arabic(goal))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(W.muted)
                }
            }
        }
        .frame(width: 104, height: 104)
    }

    private var picker: some View {
        List(TasbeehDhikr.allCases) { option in
            Button {
                dhikr = option
                showsPicker = false
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.title).font(.system(size: 14, weight: .semibold))
                        Text(option.goal.map { "\(DateHelper.arabic($0)) \(L10n.text("مرة"))" } ?? L10n.text("عدد مفتوح"))
                            .font(.system(size: 11))
                            .foregroundStyle(W.muted)
                    }
                    Spacer()
                    if option == dhikr {
                        Image(systemName: "checkmark").foregroundStyle(W.accent())
                    }
                }
            }
        }
    }

    private func increment() {
        let wasBelowGoal = !reachedGoal
        WatchSession.shared.incrementTasbeeh(dhikr)
        refresh()
        if wasBelowGoal && reachedGoal {
            WKInterfaceDevice.current().play(.success)
        } else {
            W.tap()
        }
    }

    private func refresh() {
        count = TasbeehCounter.count(of: dhikr)
    }
}
