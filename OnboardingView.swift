import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: CreatineStore

    @State private var maintenance: Double = 5
    @State private var usesLoading = false
    @State private var loadingDose: Double = 20
    @State private var loadingDays: Int = 7
    @State private var reminderTime = Calendar.current.date(
        from: DateComponents(hour: 18, minute: 0)
    ) ?? Date()

    var body: some View {
        ZStack {
            CT.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Creatine Tracker")
                            .font(CT.display(34, .heavy))
                            .foregroundStyle(CT.ink)
                        Text("One tap a day. That's the whole app.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(CT.inkSoft)
                    }
                    .padding(.top, 48)

                    card {
                        Text("Daily dose")
                            .font(CT.display(17, .semibold))
                            .foregroundStyle(CT.ink)

                        DoseStepper(value: $maintenance, range: 1...15, step: 0.5, tint: CT.accent)

                        Text("Most people settle around 5 g per day.")
                            .font(.footnote)
                            .foregroundStyle(CT.inkSoft)
                    }

                    card {
                        Toggle(isOn: $usesLoading.animation(.snappy)) {
                            Text("Start with a loading phase")
                                .font(CT.display(17, .semibold))
                                .foregroundStyle(CT.ink)
                        }
                        .tint(CT.loading)

                        if usesLoading {
                            DoseStepper(value: $loadingDose, range: 5...30, step: 1, tint: CT.loading)

                            Stepper(value: $loadingDays, in: 3...14) {
                                Text("for \(loadingDays) days")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(CT.ink)
                            }

                            Text("\(loadingDose.gramString) g daily for \(loadingDays) days, then \(maintenance.gramString) g from day \(loadingDays + 1) on. A loading dose this size is usually split across the day.")
                                .font(.footnote)
                                .foregroundStyle(CT.inkSoft)
                        }
                    }

                    card {
                        Text("Daily reminder")
                            .font(CT.display(17, .semibold))
                            .foregroundStyle(CT.ink)
                        DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        Text("You'll only get a notification on days you haven't logged yet. Changeable later.")
                            .font(.footnote)
                            .foregroundStyle(CT.inkSoft)
                    }

                    Button(action: start) {
                        Text("Start tracking")
                            .font(CT.display(19, .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(CT.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CT.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func start() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        store.update {
            $0.maintenanceDose = maintenance
            $0.usesLoadingPhase = usesLoading
            $0.loadingDose = loadingDose
            $0.loadingDays = loadingDays
            $0.reminderEnabled = true
            $0.reminderHour = comps.hour ?? 18
            $0.reminderMinute = comps.minute ?? 0
        }
        store.completeOnboarding()
    }
}

/// Büyük, okunaklı doz seçici — asıl rakam ekranın kahramanı.
struct DoseStepper: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let tint: Color

    var body: some View {
        HStack(spacing: 18) {
            button("minus") { value = max(range.lowerBound, value - step) }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value.gramString)
                    .font(CT.display(46, .heavy))
                    .foregroundStyle(CT.ink)
                    .contentTransition(.numericText())
                Text("g")
                    .font(CT.display(22, .semibold))
                    .foregroundStyle(CT.inkSoft)
            }
            .frame(maxWidth: .infinity)

            button("plus") { value = min(range.upperBound, value + step) }
        }
        .animation(.snappy, value: value)
    }

    private func button(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .background(tint.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
    }
}
