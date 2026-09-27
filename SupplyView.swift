import SwiftUI

struct SupplyView: View {
    @EnvironmentObject private var store: CreatineStore
    @State private var showRestockSheet = false
    @State private var restockAmount: Double = 500

    var body: some View {
        NavigationStack {
            ZStack {
                CT.bg.ignoresSafeArea()

                if store.settings.trackSupply {
                    ScrollView {
                        VStack(spacing: 20) {
                            gauge
                            stats
                            actions
                            correction
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle(L.tabSupply)
        }
        .sheet(isPresented: $showRestockSheet) { restockSheet }
    }

    // MARK: - Kapalıyken

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "shippingbox")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(CT.inkSoft)

            VStack(spacing: 8) {
                Text(L.supplyEmptyTitle)
                    .font(CT.display(22, .bold))
                    .foregroundStyle(CT.ink)
                    .multilineTextAlignment(.center)
                Text(L.supplyEmptyBody)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
                    .multilineTextAlignment(.center)
            }

            Button {
                restockAmount = store.settings.containerGrams
                showRestockSheet = true
            } label: {
                Text(L.supplySetup)
                    .font(CT.display(17, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(CT.accent, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(32)
    }

    // MARK: - Gösterge

    private var gauge: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: store.settings.supplyRemaining.gramString)
                    .font(CT.display(56, .heavy))
                    .foregroundStyle(CT.ink)
                    .contentTransition(.numericText())
                Text(L.supplyGLeft)
                    .font(CT.display(20, .semibold))
                    .foregroundStyle(CT.inkSoft)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(CT.hairline)
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(6, geo.size.width * store.settings.supplyFraction))
                }
            }
            .frame(height: 12)
            .animation(.snappy, value: store.settings.supplyRemaining)

            Text(L.supplyOfContainer(store.settings.containerGrams.gramString))
                .font(.caption.weight(.medium))
                .foregroundStyle(CT.inkSoft)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.top, 8)
    }

    private var barColor: Color {
        (store.settings.supplyIsEmpty || store.settings.supplyIsLow) ? CT.loading : CT.accent
    }

    // MARK: - Sayılar

    private var stats: some View {
        HStack(spacing: 12) {
            box(value: "\(store.settings.supplyDaysLeft)", label: L.supplyDaysLeft)
            box(
                value: store.settings.supplyRunOutDate.map {
                    $0.formatted(.dateTime.day().month(.abbreviated))
                } ?? "—",
                label: L.supplyRunsOut
            )
            box(value: "\(store.todayDose.gramString) g", label: L.supplyPerDay)
        }
    }

    private func box(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(verbatim: value)
                .font(CT.display(20, .heavy))
                .foregroundStyle(CT.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(CT.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Eylemler

    private var actions: some View {
        VStack(spacing: 12) {
            if store.settings.supplyIsEmpty {
                notice(L.supplyOut, color: CT.loading)
            } else if store.settings.supplyIsLow {
                notice(L.supplyLow(store.settings.supplyDaysLeft), color: CT.loading)
            }

            Button {
                restockAmount = store.settings.containerGrams
                showRestockSheet = true
            } label: {
                Label(L.supplyNewContainer, systemImage: "plus.circle.fill")
                    .font(CT.display(17, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(CT.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func notice(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(.footnote, design: .rounded).weight(.medium))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Elle düzeltme

    private var correction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.supplyCorrect)
                .font(CT.display(15, .semibold))
                .foregroundStyle(CT.ink)

            Stepper(value: Binding(
                get: { store.settings.supplyRemaining },
                set: { new in store.update { $0.supplyRemaining = max(0, new) } }
            ), in: 0...store.settings.containerGrams, step: 5) {
                Text(L.supplyRemaining(store.settings.supplyRemaining.gramString))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
            }

            Divider().background(CT.hairline)

            Button(role: .destructive) {
                store.update { $0.trackSupply = false }
            } label: {
                Text(L.supplyTurnOff)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Yeni kutu

    private var restockSheet: some View {
        NavigationStack {
            ZStack {
                CT.bg.ignoresSafeArea()
                VStack(spacing: 28) {
                    Text(L.supplySheetQ)
                        .font(CT.display(24, .bold))
                        .foregroundStyle(CT.ink)
                        .multilineTextAlignment(.center)

                    DoseStepper(value: $restockAmount, range: 50...2000, step: 50, tint: CT.accent)

                    HStack(spacing: 10) {
                        ForEach([250.0, 300.0, 500.0, 1000.0], id: \.self) { preset in
                            Button {
                                restockAmount = preset
                            } label: {
                                Text(verbatim: "\(preset.gramString)g")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(restockAmount == preset ? .white : CT.ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        restockAmount == preset ? CT.accent : CT.surface,
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text(L.supplySheetHint)
                        .font(.footnote)
                        .foregroundStyle(CT.inkSoft)
                        .multilineTextAlignment(.center)

                    Spacer()

                    Button {
                        store.update {
                            $0.trackSupply = true
                            $0.containerGrams = restockAmount
                        }
                        store.restock(to: restockAmount)
                        showRestockSheet = false
                    } label: {
                        Text(L.supplySheetStart)
                            .font(CT.display(17, .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(CT.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
            .navigationTitle(L.supplyNewContainer)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.commonCancel) { showRestockSheet = false }
                }
            }
        }
        .presentationDetents([.large])
    }
}
