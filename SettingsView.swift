import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: CreatineStore
    @State private var reminderTime = Date()
    @State private var showResetConfirm = false
    @State private var permissionDenied = false

    private let intervalOptions = [15, 30, 60, 120]

    private func intervalLabel(_ minutes: Int) -> String {
        minutes < 60 ? L.settingsMinutes(minutes) : L.settingsHours(minutes / 60)
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Dose
                Section(L.settingsDose) {
                    HStack {
                        Text(L.onbDailyDose)
                        Spacer()
                        Text(verbatim: "\(store.settings.maintenanceDose.gramString) g")
                            .foregroundStyle(CT.inkSoft)
                    }
                    Stepper(L.settingsAdjust, value: Binding(
                        get: { store.settings.maintenanceDose },
                        set: { new in store.update { $0.maintenanceDose = new } }
                    ), in: 1...15, step: 0.5)
                    .labelsHidden()
                }

                // MARK: Loading
                Section {
                    Toggle(L.settingsLoadingPhase, isOn: Binding(
                        get: { store.settings.usesLoadingPhase },
                        set: { new in store.update { $0.usesLoadingPhase = new } }
                    ))

                    if store.settings.usesLoadingPhase {
                        HStack {
                            Text(L.settingsLoadingDose)
                            Spacer()
                            Text(verbatim: "\(store.settings.loadingDose.gramString) g")
                                .foregroundStyle(CT.inkSoft)
                        }
                        Stepper(L.settingsAdjustLoading, value: Binding(
                            get: { store.settings.loadingDose },
                            set: { new in store.update { $0.loadingDose = new } }
                        ), in: 5...30, step: 1)
                        .labelsHidden()

                        Stepper(value: Binding(
                            get: { store.settings.loadingDays },
                            set: { new in store.update { $0.loadingDays = new } }
                        ), in: 3...14) {
                            Text(L.settingsLength(store.settings.loadingDays))
                        }

                        DatePicker(L.settingsStartedOn, selection: Binding(
                            get: { store.settings.startDate },
                            set: { new in store.update { $0.startDate = DayKey.startOfDay(new) } }
                        ), displayedComponents: .date)
                    }
                } footer: {
                    if store.settings.usesLoadingPhase {
                        Text(L.settingsLoadingFooter(store.settings.loadingDaysRemaining))
                    }
                }

                // MARK: Reminder
                Section {
                    Toggle(L.onbReminder, isOn: Binding(
                        get: { store.settings.reminderEnabled },
                        set: { new in
                            store.update { $0.reminderEnabled = new }
                            if new { requestPermissionIfNeeded() }
                        }
                    ))

                    if store.settings.reminderEnabled {
                        DatePicker(L.settingsTime, selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, new in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: new)
                                store.update {
                                    $0.reminderHour = comps.hour ?? 18
                                    $0.reminderMinute = comps.minute ?? 0
                                }
                            }
                    }
                } header: {
                    Text(L.settingsNotifications)
                } footer: {
                    Text(permissionDenied ? L.settingsDenied : L.settingsOnlyUnlogged)
                }

                // MARK: Repeat
                if store.settings.reminderEnabled {
                    Section {
                        Toggle(L.settingsRemindAgain, isOn: Binding(
                            get: { store.settings.repeatEnabled },
                            set: { new in store.update { $0.repeatEnabled = new } }
                        ))

                        if store.settings.repeatEnabled {
                            Picker(L.settingsEvery, selection: Binding(
                                get: { store.settings.repeatIntervalMinutes },
                                set: { new in store.update { $0.repeatIntervalMinutes = new } }
                            )) {
                                ForEach(intervalOptions, id: \.self) { minutes in
                                    Text(intervalLabel(minutes)).tag(minutes)
                                }
                            }

                            Stepper(value: Binding(
                                get: { store.settings.repeatCount },
                                set: { new in store.update { $0.repeatCount = new } }
                            ), in: 1...4) {
                                Text(L.settingsUpTo(store.settings.repeatCount))
                            }
                        }
                    } header: {
                        Text(L.settingsRepeat)
                    } footer: {
                        if store.settings.repeatEnabled {
                            Text(L.settingsRepeatFooterOn(
                                store.settings.reminderTimeLocalized,
                                intervalLabel(store.settings.repeatIntervalMinutes)
                            ))
                        } else {
                            Text(L.settingsRepeatFooterOff)
                        }
                    }
                }

                // MARK: Widget
                Section(L.settingsWidget) {
                    Label(L.settingsWidgetHelp, systemImage: "square.grid.2x2")
                        .font(.footnote)
                        .foregroundStyle(CT.inkSoft)
                }

                // MARK: Data
                Section {
                    Button(L.settingsReset, role: .destructive) { showResetConfirm = true }
                } footer: {
                    Text(L.settingsLocalOnly)
                }
            }
            .navigationTitle(L.tabSettings)
            .scrollContentBackground(.hidden)
            .background(CT.bg)
        }
        .task {
            reminderTime = Calendar.current.date(
                from: DateComponents(hour: store.settings.reminderHour, minute: store.settings.reminderMinute)
            ) ?? Date()
            let status = await NotificationManager.authorizationStatus()
            permissionDenied = (status == .denied)
        }
        .confirmationDialog(L.settingsResetTitle, isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button(L.settingsDeleteAll, role: .destructive) { store.resetEverything() }
            Button(L.commonCancel, role: .cancel) {}
        } message: {
            Text(L.settingsResetMsg)
        }
    }

    private func requestPermissionIfNeeded() {
        Task {
            let status = await NotificationManager.authorizationStatus()
            if status == .notDetermined {
                _ = await NotificationManager.requestAuthorization()
            }
            permissionDenied = await NotificationManager.authorizationStatus() == .denied
            await NotificationManager.reschedule()
        }
    }
}
