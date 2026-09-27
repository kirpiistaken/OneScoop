import SwiftUI
import UIKit

struct TodayView: View {
    @EnvironmentObject private var store: CreatineStore
    @State private var checkScale: CGFloat = 0.6

    var body: some View {
        ZStack {
            (store.isTodayTaken ? CT.accentSoft : CT.bg)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.35), value: store.isTodayTaken)

            VStack(spacing: 0) {
                header
                Spacer(minLength: 12)

                if store.isTodayTaken {
                    takenState
                } else {
                    askState
                }

                Spacer(minLength: 12)
                footer
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(CT.inkSoft)
                if store.settings.isLoadingDay(Date()) {
                    Text(L.todayLoadingLeft(store.settings.loadingDaysRemaining))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(CT.loading)
                }
            }
            Spacer()
            if store.streak > 1 {
                Text(L.todayStreak(store.streak))
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(CT.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(CT.accent.opacity(0.12), in: Capsule())
            }
        }
    }

    // MARK: - States

    private var askState: some View {
        VStack(spacing: 36) {
            VStack(spacing: 14) {
                Text(L.todayQuestion)
                    .font(CT.display(40, .heavy))
                    .foregroundStyle(CT.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-2)
                    .minimumScaleFactor(0.7)

                Text(L.todayDose(store.todayDose.gramString))
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(CT.inkSoft)
            }

            Button {
                withAnimation(.snappy) {
                    checkScale = 0.6
                    store.markTaken()
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.05)) {
                    checkScale = 1
                }
            } label: {
                Text(L.todayYes)
                    .font(CT.display(38, .heavy))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, 20)
                    .frame(width: 200, height: 200)
                    .background(CT.accent, in: Circle())
                    .shadow(color: CT.accent.opacity(0.35), radius: 24, y: 10)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel(L.todayYesA11y)
        }
    }

    private var takenState: some View {
        VStack(spacing: 26) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 132, weight: .bold))
                .foregroundStyle(CT.accent)
                .scaleEffect(checkScale)
                .onAppear { checkScale = 1 }

            VStack(spacing: 10) {
                Text(L.todayDoneTitle)
                    .font(CT.display(30, .bold))
                    .foregroundStyle(CT.ink)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)

                if let entry = store.todayEntry {
                    Text(L.todayLoggedAt(
                        entry.grams.gramString,
                        entry.takenAt.formatted(date: .omitted, time: .shortened)
                    ))
                    .font(.system(.callout, design: .rounded).weight(.medium))
                    .foregroundStyle(CT.inkSoft)
                }
            }

            Button {
                withAnimation(.snappy) { store.undo() }
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            } label: {
                Label(L.todayUndo, systemImage: "arrow.uturn.backward")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(CT.inkSoft)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(CT.surface.opacity(0.8), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Group {
            if store.settings.reminderEnabled && !store.isTodayTaken {
                Text(L.todayReminderSet(store.settings.reminderTimeLocalized))
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(CT.inkSoft)
            } else if store.isTodayTaken {
                Text(L.todaySeeYou)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(CT.inkSoft)
            }
        }
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
