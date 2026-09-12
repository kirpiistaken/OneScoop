import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: CreatineStore
    @State private var reminderTime = Date()
    @State private var showResetConfirm = false
    @State private var permissionDenied = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Dose
                Section("Dose") {
                    HStack {
                        Text("Daily dose")
                        Spacer()
                        Text("\(store.settings.maintenanceDose.gramString) g")
                            .foregroundStyle(CT.inkSoft)
                    }
                    Stepper("Adjust", value: Binding(
                        get: { store.settings.maintenanceDose },
                        set: { new in store.update { $0.maintenanceDose = new } }
                    ), in: 1...15, step: 0.5)
                    .labelsHidden()
                }

                // MARK: Loading
                Section {
                    Toggle("Loading phase", isOn: Binding(
                        get: { store.settings.usesLoadingPhase },
                        set: { new in store.update { $0.usesLoadingPhase = new } }
                    ))

                    if store.settings.usesLoadingPhase {
                        HStack {
                            Text("Loading dose")
                            Spacer()
                            Text("\(store.settings.loadingDose.gramString) g")
                                .foregroundStyle(CT.inkSoft)
                        }
                        Stepper("Adjust loading dose", value: Binding(
                            get: { store.settings.loadingDose },
                            set: { new in store.update { $0.loadingDose = new } }
                        ), in: 5...30, step: 1)
                        .labelsHidden()

                        Stepper(value: Binding(
                            get: { store.settings.loadingDays },
                            set: { new in store.update { $0.loadingDays = new } }
                        ), in: 3...14) {
                            Text("Length: \(store.settings.loadingDays) days")
                        }

                        DatePicker("Started on", selection: Binding(
                            get: { store.settings.startDate },
                            set: { new in store.update { $0.startDate = DayKey.startOfDay(new) } }
                        ), displayedComponents: .date)
                    }
                } footer: {
                    if store.settings.usesLoadingPhase {
                        Text("\(store.settings.loadingDaysRemaining) day(s) of loading left. A dose this size is usually split into several servings across the day.")
                    }
                }

                // MARK: Reminder
                Section {
                    Toggle("Daily reminder", isOn: Binding(
                        get: { store.settings.reminderEnabled },
                        set: { new in
                            store.update { $0.reminderEnabled = new }
                            if new { requestPermissionIfNeeded() }
                        }
                    ))

                    if store.settings.reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, new in
                                let comps = Calendar.current.dateComponents([.hour, .minute], from: new)
                                store.update {
                                    $0.reminderHour = comps.hour ?? 18
                                    $0.reminderMinute = comps.minute ?? 0
                                }
                            }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if permissionDenied {
                        Text("Notifications are turned off for Creatine Tracker in iOS Settings. Turn them on there to get reminders.")
                    } else {
                        Text("You'll only be notified on days you haven't logged a dose yet.")
                    }
                }

                // MARK: Widget
                Section("Widget") {
                    Label("Long-press your home screen, tap Edit, then Add Widget and pick OneScoop. You can log the dose straight from the widget.", systemImage: "square.grid.2x2")
                        .font(.footnote)
                        .foregroundStyle(CT.inkSoft)
                }

                // MARK: Data
                Section {
                    Button("Reset all data", role: .destructive) { showResetConfirm = true }
                } footer: {
                    Text("Everything is stored on this device only. Nothing is uploaded anywhere.")
                }
            }
            .navigationTitle("Settings")
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
        .confirmationDialog("Reset all data?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Delete everything", role: .destructive) { store.resetEverything() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your history and settings, and takes you back to setup.")
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
