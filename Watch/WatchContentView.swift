import SwiftUI

/// Saatte tek ekran: soru, "Yes" butonu ve seri. Takvim ve ayarlar yok.
struct WatchContentView: View {
    @EnvironmentObject private var model: WatchModel
    @Environment(\.scenePhase) private var scenePhase

    private let accent = Color(red: 0.36, green: 0.53, blue: 1.0)      // #5C86FF
    private let soft = Color(red: 0.58, green: 0.61, blue: 0.65)       // #939CA6

    var body: some View {
        let t = model.today

        Group {
            if !t.onboarded {
                Text(L.watchSetupFirst)
                    .font(.system(.body, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(soft)
                    .padding()
            } else if t.isTaken {
                taken(t)
            } else {
                ask(t)
            }
        }
        .animation(.snappy, value: t.isTaken)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refresh() }
        }
    }

    // MARK: - Soru

    private func ask(_ t: WatchModel.Today) -> some View {
        VStack(spacing: 8) {
            Text(L.todayQuestion)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(3)

            Button {
                model.log()
            } label: {
                Text(L.todayYes)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 10)
                    .frame(width: 92, height: 92)
                    .background(accent, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L.todayYesA11y)

            streakLine(t)
        }
    }

    // MARK: - Alındı

    private func taken(_ t: WatchModel.Today) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(accent)

            Text(L.widgetDoseLogged)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)

            streakLine(t)

            Button(L.todayUndo) { model.undo() }
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(soft)
                .buttonStyle(.plain)
                .padding(.top, 2)
        }
    }

    // MARK: - Seri

    @ViewBuilder
    private func streakLine(_ t: WatchModel.Today) -> some View {
        if t.streak > 1 {
            Text(L.todayStreak(t.streak))
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
