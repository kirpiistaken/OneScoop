import SwiftUI
import UIKit

// 2.0 — Su takibinin uygulama içi ekranları. Sadece uygulama target'ında.

// MARK: - Bugün ekranındaki su kartı

/// Üstte bardak + toplam + tempo; altta üç kap butonu ve geri al.
/// Kaba dokun = o kap kadar eklenir. Geri al her basışta en son kaydı siler.
struct WaterCard: View {
    @EnvironmentObject private var store: CreatineStore
    @EnvironmentObject private var plus: PlusStore

    @State private var wavePhase: Double = 0
    @State private var showEntries = false
    @State private var showPaywall = false

    private var total: Int { store.waterTotalToday }
    /// Antrenman günlerinde ek dahil (OneScoop+).
    private var goal: Int { _ = store.water; return WaterData.goal() }
    private var fraction: Double { goal > 0 ? Double(total) / Double(goal) : 0 }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                WaterGlass(fraction: fraction, wavePhase: wavePhase)
                    .frame(width: 42, height: 60)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: fraction)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(L.waterTitle)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(CT.inkSoft)
                        Spacer()
                        Text(verbatim: "\(total.litersString) / \(goal.litersString) L")
                            .font(CT.display(20, .bold))
                            .foregroundStyle(CT.ink)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: total)
                    }
                    // Tempo cümlesi kendi satırında; sığmazsa ikinci satıra
                    // geçer, "..." ile kesilmez.
                    Text(paceText)
                        .font(.system(.footnote, design: .rounded).weight(.medium))
                        .foregroundStyle(CT.inkSoft)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    // Antrenman günü: hedefe eklenen miktar (OneScoop+).
                    // Tempo cümlesine yer açmak için onun altında.
                    if WaterData.hasWorkoutBoost() {
                        Label(L.waterWorkoutBoost(String(store.water.workoutBoostMl)),
                              systemImage: "figure.strengthtraining.traditional")
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundStyle(CT.accent)
                            .lineLimit(1)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { showEntries = true }

            HStack(alignment: .top, spacing: 14) {
                ForEach(store.water.cups) { cup in
                    CupButton(cup: cup) { add(cup.ml) }
                }
                Spacer(minLength: 0)
                undoButton
            }
        }
        .padding(16)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .sheet(isPresented: $showEntries) { WaterEntriesSheet() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    /// Tempo: saate göre şu ana kadar içilmiş olması gereken miktarla fark.
    /// Ham ml yerine butonlara bağlı söyleniyor: açığı kapatan en küçük kap
    /// ("Bir shaker içersen tempoya yetişirsin"); o da yetmiyorsa 50'ye
    /// yuvarlanmış litre.
    private var paceText: String {
        if total >= goal { return L.waterGoalReached }
        let behind = WaterReminders.expected() - total
        guard behind > 150 else { return L.waterPaceOn }
        if let cup = store.water.cups.filter({ $0.ml >= behind }).min(by: { $0.ml < $1.ml }) {
            switch cup.kind {
            case .glass: return L.waterCatchGlass
            case .shaker: return L.waterCatchShaker
            case .bottle: return L.waterCatchBottle
            }
        }
        let rounded = Int((Double(behind) / 50).rounded()) * 50
        return L.waterPaceBehind(rounded.litersString)
    }

    /// Her basış en son girilen suyu siler; art arda basılabilir.
    private var undoButton: some View {
        let canUndo = store.canUndoWater
        return Button {
            store.undoLastWater()
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(canUndo ? CT.ink : CT.inkSoft.opacity(0.4))
                .frame(width: 44, height: 44)
                .background(CT.bg, in: Circle())
                .overlay(Circle().stroke(CT.hairline, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
        .disabled(!canUndo)
        .padding(.top, 7)          // kap dairelerinin ortasına hizalı
        .accessibilityLabel(L.todayUndo)
    }

    private func add(_ ml: Int) {
        store.addWater(ml)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.easeInOut(duration: 1.2)) { wavePhase += 2 * .pi }
    }
}

/// Yuvarlak kap butonu: simge + altında hacmi.
struct CupButton: View {
    var cup: WaterCup
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                CupIcon(kind: cup.kind)
                    .fill(CT.accent)
                    .frame(width: 30, height: 28)
                    .frame(width: 58, height: 58)
                    .background(CT.accent.opacity(0.14), in: Circle())
                Text(verbatim: "\(cup.ml) ml")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(CT.inkSoft)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(verbatim: "\(cup.kind.title), \(cup.ml) ml"))
    }
}

// MARK: - Günün kayıtları

struct WaterEntriesSheet: View {
    @EnvironmentObject private var store: CreatineStore
    @Environment(\.dismiss) private var dismiss

    /// Hangi gün (Bugün kartından bugün, takvimden seçilen gün).
    var date: Date = Date()
    @State private var entries: [WaterEntry] = []

    private var isToday: Bool { DayKey.key(for: date) == DayKey.today }
    private var total: Int { entries.reduce(0) { $0 + $1.ml } }

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    Text(L.waterNoEntries)
                        .foregroundStyle(CT.inkSoft)
                } else {
                    Section {
                        ForEach(entries.reversed()) { entry in
                            row(entry)
                        }
                    } footer: {
                        Text(verbatim: "\(total.litersString) / \(WaterData.goal(on: date).litersString) L")
                    }
                }
            }
            .navigationTitle(isToday ? L.waterTodayEntries
                             : date.formatted(.dateTime.day().month(.wide).weekday(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.commonDone) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear(perform: load)
        .onChange(of: store.waterToday) { _, _ in load() }
    }

    @ViewBuilder
    private func row(_ entry: WaterEntry) -> some View {
        let content = HStack {
            Text(entry.at, style: .time)
                .foregroundStyle(CT.inkSoft)
            if entry.isFromHealth {
                // Başka bir uygulamadan Apple Sağlık üzerinden geldi.
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.pink)
                    .accessibilityLabel(L.settingsWaterHealth)
            }
            Spacer()
            Text(verbatim: "\(entry.ml) ml")
                .font(.system(.body, design: .rounded).weight(.semibold))
        }
        if entry.isFromHealth {
            content
        } else {
            content.swipeActions {
                Button(role: .destructive) {
                    store.removeWater(entry.id)
                    load()
                } label: {
                    Label(L.waterDelete, systemImage: "trash")
                }
                .tint(.red)
            }
        }
    }

    private func load() {
        entries = WaterData.entries(on: date)
    }
}

// MARK: - "Yeni: Su" tanıtımı (2.0 ilk açılış)

struct WaterIntroSheet: View {
    @EnvironmentObject private var store: CreatineStore
    @Environment(\.dismiss) private var dismiss
    @State private var fill = 0.15

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 8)
            WaterGlass(fraction: fill, wavePhase: fill * 10)
                .frame(width: 70, height: 100)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.6).delay(0.2)) { fill = 0.7 }
                }

            VStack(spacing: 10) {
                Text(L.whatsnewWaterTitle)
                    .font(CT.display(30, .heavy))
                    .foregroundStyle(CT.ink)
                    .multilineTextAlignment(.center)
                Text(L.whatsnewWaterBody)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)

            Spacer(minLength: 8)

            Button {
                store.updateWater {
                    $0.enabled = true
                    $0.hasSeenIntro = true
                }
                dismiss()
            } label: {
                Text(L.whatsnewWaterTry)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(CT.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(PressableStyle())

            Button(L.plusNotNow) {
                store.updateWater { $0.hasSeenIntro = true }
                dismiss()
            }
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(CT.inkSoft)
        }
        .padding(24)
        .background(CT.bg.ignoresSafeArea())
        .presentationDetents([.fraction(0.68), .large])
        .interactiveDismissDisabled()
    }
}
