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
            .navigationTitle("Supply")
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
                Text("Know when you'll run out")
                    .font(CT.display(22, .bold))
                    .foregroundStyle(CT.ink)
                Text("Tell OneScoop how big your tub is. Every dose you log is subtracted, so you always know how many days you have left.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
                    .multilineTextAlignment(.center)
            }

            Button {
                restockAmount = store.settings.containerGrams
                showRestockSheet = true
            } label: {
                Text("Set up supply")
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
                Text(store.settings.supplyRemaining.gramString)
                    .font(CT.display(56, .heavy))
                    .foregroundStyle(CT.ink)
                    .contentTransition(.numericText())
                Text("g left")
                    .font(CT.display(20, .semibold))
                    .foregroundStyle(CT.inkSoft)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CT.hairline)
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(6, geo.size.width * store.settings.supplyFraction))
                }
            }
            .frame(height: 12)
            .animation(.snappy, value: store.settings.supplyRemaining)

            Text("of \(store.settings.containerGrams.gramString) g container")
                .font(.caption.weight(.medium))
                .foregroundStyle(CT.inkSoft)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.top, 8)
    }

    private var barColor: Color {
        if store.settings.supplyIsEmpty { return CT.loading }
        return store.settings.supplyIsLow ? CT.loading : CT.accent
    }

    // MARK: - Sayılar

    private var stats: some View {
        HStack(spacing: 12) {
            box(value: "\(store.settings.supplyDaysLeft)", label: "days left")
            box(
                value: store.settings.supplyRunOutDate.map {
                    $0.formatted(.dateTime.day().month(.abbreviated))
                } ?? "—",
                label: "runs out"
            )
            box(value: "\(store.todayDose.gramString) g", label: "per day")
        }
    }

    private func box(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(CT.display(20, .heavy))
                .foregroundStyle(CT.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(CT.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(CT.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Eylemler

    private var actions: some View {
        VStack(spacing: 12) {
            if store.settings.supplyIsEmpty {
                notice("You're out. Log a new container when it arrives.", color: CT.loading)
            } else if store.settings.supplyIsLow {
                notice("Running low — about \(store.settings.supplyDaysLeft) day(s) left. Good time to reorder.", color: CT.loading)
            }

            Button {
                restockAmount = store.settings.containerGrams
                showRestockSheet = true
            } label: {
                Label("New container", systemImage: "plus.circle.fill")
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
            Text("Correct the amount")
                .font(CT.display(15, .semibold))
                .foregroundStyle(CT.ink)

            Stepper(value: Binding(
                get: { store.settings.supplyRemaining },
                set: { new in store.update { $0.supplyRemaining = max(0, new) } }
            ), in: 0...store.settings.containerGrams, step: 5) {
                Text("\(store.settings.supplyRemaining.gramString) g remaining")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(CT.inkSoft)
            }

            Divider().background(CT.hairline)

            Button(role: .destructive) {
                store.update { $0.trackSupply = false }
            } label: {
                Text("Turn off supply tracking")
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
                    Text("How big is the container?")
                        .font(CT.display(24, .bold))
                        .foregroundStyle(CT.ink)
                        .multilineTextAlignment(.center)

                    DoseStepper(value: $restockAmount, range: 50...2000, step: 50, tint: CT.accent)

                    HStack(spacing: 10) {
                        ForEach([250.0, 300.0, 500.0, 1000.0], id: \.self) { preset in
                            Button {
                                restockAmount = preset
                            } label: {
                                Text("\(preset.gramString)g")
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

                    Text("Each logged dose is subtracted from this. You can correct the remaining amount any time.")
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
                        Text("Start with a full container")
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
            .navigationTitle("New container")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showRestockSheet = false }
                }
            }
        }
        .presentationDetents([.large])
    }
}
