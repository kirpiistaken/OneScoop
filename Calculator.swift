import SwiftUI

// 2.1 — Kreatin-su hesaplayıcı (ücretsiz). Ayarlar'dan tam ekran açılır.
//
// Hesap (pratik kural, tıbbi tavsiye değil; ekranda yazıyor):
//   temel ihtiyaç  = kilo × 35 ml
//   kreatin        = gram × 100 ml   (5 g → +0,5 L, 10 g → +1 L)
//   antrenman günü = +500 ml (isteğe bağlı)
// Sonuç 50 ml'ye yuvarlanır. Doz, kullanıcının bugünkü dozuyla gelir;
// "ya 10 g alsaydım" diye değiştirilebilir.

enum WaterCalc {
    static let mlPerKg = 35.0
    static let mlPerGram = 100.0
    static let workoutMl = 500.0

    static func total(kg: Double, grams: Double, workout: Bool) -> Int {
        let raw = kg * mlPerKg + grams * mlPerGram + (workout ? workoutMl : 0)
        return Int((raw / 50).rounded()) * 50
    }
}

struct CalculatorView: View {
    @EnvironmentObject private var store: CreatineStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage("ct.calc.weightKg", store: AppGroup.defaults) private var kg: Double = 75
    @State private var grams: Double = 5
    @State private var workout = false
    @State private var loadingHealth = false
    @State private var applied = false

    private var usesPounds: Bool { Locale.current.measurementSystem == .us }
    private var total: Int { WaterCalc.total(kg: kg, grams: grams, workout: workout) }
    private var myDose: Double { store.settings.dose(on: Date()) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    result
                    inputs
                    breakdown
                    applyButton
                    Text(L.calcDisclaimer)
                        .font(.footnote)
                        .foregroundStyle(CT.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(20)
            }
            .background(CT.bg.ignoresSafeArea())
            .navigationTitle(L.calcTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(L.commonDone)
                }
            }
        }
        .onAppear { grams = myDose }
    }

    // MARK: Sonuç

    private var result: some View {
        let glasses = Int((Double(total) / 250).rounded(.up))
        return VStack(spacing: 10) {
            Text(L.calcResultLabel)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(CT.inkSoft)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: total.litersString)
                    .font(CT.display(64, .heavy))
                    .foregroundStyle(CT.ink)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: total)
                Text(verbatim: "L")
                    .font(CT.display(28, .bold))
                    .foregroundStyle(CT.inkSoft)
            }
            // Bardaklar: her biri 250 ml
            let columns = Array(repeating: GridItem(.fixed(22), spacing: 6), count: min(10, max(glasses, 1)))
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<min(glasses, 20), id: \.self) { _ in
                    CupIcon(kind: .glass)
                        .fill(CT.accent)
                        .frame(width: 18, height: 22)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: glasses)
            Text(L.calcGlasses(glasses))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(CT.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: Girdiler

    private var inputs: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L.calcWeight).font(.system(.subheadline, design: .rounded).weight(.bold))
                    Spacer()
                    Text(verbatim: weightText).font(.system(.subheadline, design: .rounded).weight(.heavy)).monospacedDigit()
                }
                Slider(value: $kg, in: 40...150, step: 1)
                    .tint(CT.accent)
                if HealthSync.isAvailable {
                    Button {
                        Task {
                            loadingHealth = true
                            if let w = await HealthSync.latestBodyMassKg() { kg = min(150, max(40, w.rounded())) }
                            loadingHealth = false
                        }
                    } label: {
                        Label(L.calcFromHealth, systemImage: "heart.fill")
                            .font(.footnote.weight(.semibold))
                    }
                    .tint(.pink)
                    .disabled(loadingHealth)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(L.calcDose).font(.system(.subheadline, design: .rounded).weight(.bold))
                    Spacer()
                    Text(verbatim: "\(grams.gramString) g").font(.system(.subheadline, design: .rounded).weight(.heavy)).monospacedDigit()
                }
                Slider(value: $grams, in: 1...25, step: 0.5)
                    .tint(CT.accent)
                if grams != myDose {
                    Button(L.calcMyDose(myDose.gramString)) { withAnimation(.snappy) { grams = myDose } }
                        .font(.footnote.weight(.semibold))
                }
            }

            Divider()

            Toggle(isOn: $workout) {
                Label(L.calcWorkout, systemImage: "figure.strengthtraining.traditional")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
            }
            .tint(CT.accent)
        }
        .padding(16)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var weightText: String {
        usesPounds ? "\(Int((kg * 2.20462).rounded())) lb" : "\(Int(kg)) kg"
    }

    // MARK: Döküm

    private var breakdown: some View {
        VStack(spacing: 10) {
            row(L.calcBase, "\(Int(kg * WaterCalc.mlPerKg).litersString) L")
            row(L.calcCreatine(grams.gramString), "+\(Int(grams * WaterCalc.mlPerGram).litersString) L")
            if workout { row(L.calcWorkout, "+\(Int(WaterCalc.workoutMl).litersString) L") }
        }
        .padding(16)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(verbatim: title).foregroundStyle(CT.inkSoft)
            Spacer()
            Text(verbatim: value).fontWeight(.bold).foregroundStyle(CT.ink).monospacedDigit()
        }
        .font(.system(.subheadline, design: .rounded))
    }

    // MARK: Hedef yap

    private var applyButton: some View {
        Button {
            store.updateWater {
                $0.goalMl = total
                $0.enabled = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.snappy) { applied = true }
        } label: {
            Label(applied && store.water.goalMl == total ? L.calcApplied : L.calcApply,
                  systemImage: applied && store.water.goalMl == total ? "checkmark" : "target")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(CT.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }
}
