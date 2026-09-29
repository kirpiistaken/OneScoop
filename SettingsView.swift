import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: CreatineStore
    @EnvironmentObject private var plus: PlusStore
    @State private var showPaywall = false
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

                // MARK: Su (2.0)
                Section {
                    Toggle(L.settingsWaterToggle, isOn: Binding(
                        get: { store.water.enabled },
                        set: { new in store.updateWater { $0.enabled = new } }
                    ))

                    if store.water.enabled {
                        Stepper(value: Binding(
                            get: { store.water.goalMl },
                            set: { new in store.updateWater { $0.goalMl = new } }
                        ), in: 1000...5000, step: 250) {
                            HStack {
                                Text(L.settingsWaterGoal)
                                Spacer()
                                Text(verbatim: "\(store.water.goalMl.litersString) L")
                                    .foregroundStyle(CT.inkSoft)
                            }
                        }

                        Picker(L.settingsWaterDefault, selection: Binding(
                            get: { store.water.defaultCup.id },
                            set: { new in store.updateWater { $0.defaultCupID = new } }
                        )) {
                            ForEach(store.water.cups) { cup in
                                Text(verbatim: "\(cup.kind.title) · \(cup.ml) ml").tag(cup.id)
                            }
                        }

                        if HealthSync.isAvailable {
                            Toggle(isOn: Binding(
                                get: { store.water.healthEnabled && plus.isUnlocked },
                                set: { new in
                                    guard plus.isUnlocked else { showPaywall = true; return }
                                    Task { await store.setHealthEnabled(new) }
                                }
                            )) {
                                HStack(spacing: 6) {
                                    Image(systemName: "heart.fill").foregroundStyle(.pink)
                                    Text(L.settingsWaterHealth)
                                    if !plus.isUnlocked {
                                        Image(systemName: "crown.fill")
                                            .font(.caption)
                                            .foregroundStyle(CT.gold)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text(L.settingsWater)
                } footer: {
                    if store.water.enabled {
                        Text(store.water.healthEnabled && plus.isUnlocked
                             ? L.settingsWaterHealthFooter + "\n\n" + L.settingsWaterFooter
                             : L.settingsWaterFooter)
                    }
                }

                if store.water.enabled {
                    Section {
                        ForEach(Array(store.water.cups.enumerated()), id: \.element.id) { index, cup in
                            Stepper(value: Binding(
                                get: { cup.ml },
                                set: { new in store.updateWater { $0.cups[index].ml = new } }
                            ), in: 100...1500, step: 50) {
                                cupLabel(cup)
                            }
                            .plusGated(plus.isUnlocked) { showPaywall = true } locked: {
                                cupLabel(cup)
                            }
                        }
                    } header: {
                        Text(L.settingsWaterCups)
                    } footer: {
                        Text(L.settingsWaterCupsFooter)
                    }
                }

                // MARK: Su hatırlatmaları (2.0)
                if store.water.enabled {
                    Section {
                        Picker(L.settingsWaterReminders, selection: Binding(
                            get: { store.water.reminderMode },
                            set: { new in setWaterReminder(new) }
                        )) {
                            Text(L.settingsWaterRemindOff).tag(WaterReminderMode.off)
                            Text(L.settingsWaterRemindSimple).tag(WaterReminderMode.simple)
                            Label(L.settingsWaterRemindSmart, systemImage: "crown.fill")
                                .tag(WaterReminderMode.smart)
                        }

                        if store.water.reminderMode == .simple {
                            Stepper(value: Binding(
                                get: { store.water.simpleIntervalHours },
                                set: { new in store.updateWater { $0.simpleIntervalHours = new } }
                            ), in: 1...4) {
                                Text(L.settingsWaterEvery(store.water.simpleIntervalHours))
                            }
                        }

                        // Akıllıda gün penceresi sorulmuyor; öğrenilen düzenden çıkıyor.
                        if store.water.reminderMode == .simple {
                            Stepper(value: Binding(
                                get: { store.water.wakeHour },
                                set: { new in store.updateWater { $0.wakeHour = new } }
                            ), in: 5...12) {
                                HStack {
                                    Text(L.settingsWaterDayStart)
                                    Spacer()
                                    Text(verbatim: String(format: "%02d:00", store.water.wakeHour))
                                        .foregroundStyle(CT.inkSoft)
                                }
                            }
                            Stepper(value: Binding(
                                get: { store.water.sleepHour },
                                set: { new in store.updateWater { $0.sleepHour = new } }
                            ), in: 18...23) {
                                HStack {
                                    Text(L.settingsWaterDayEnd)
                                    Spacer()
                                    Text(verbatim: String(format: "%02d:00", store.water.sleepHour))
                                        .foregroundStyle(CT.inkSoft)
                                }
                            }
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Text(L.settingsWaterReminders)
                            if store.water.reminderMode == .smart {
                                Image(systemName: "crown.fill").foregroundStyle(CT.gold)
                            }
                        }
                    } footer: {
                        switch store.water.reminderMode {
                        case .off:
                            Text(L.settingsWaterRemindOffFooter)
                        case .simple:
                            Text(L.settingsWaterRemindSimpleFooter)
                        case .smart:
                            let learned = WaterReminders.learnedDayCount()
                            if learned >= WaterReminders.daysToLearn {
                                Text(L.settingsWaterRemindSmartReady)
                            } else {
                                Text(L.settingsWaterRemindSmartLearning(learned, WaterReminders.daysToLearn))
                            }
                        }
                    }
                }

                // MARK: OneScoop+
                Section {
                    Button { showPaywall = true } label: {
                        HStack {
                            Label {
                                Text(verbatim: "OneScoop+").foregroundStyle(CT.ink)
                            } icon: {
                                Image(systemName: "crown.fill").foregroundStyle(CT.gold)
                            }
                            Spacer()
                            if plus.purchased {
                                Image(systemName: "checkmark").foregroundStyle(CT.accent)
                            } else if let price = plus.product?.displayPrice {
                                Text(verbatim: price).foregroundStyle(CT.inkSoft)
                            }
                        }
                    }
                }

                // MARK: Widget
                Section(L.settingsWidget) {
                    Label(L.settingsWidgetHelp, systemImage: "square.grid.2x2")
                        .font(.footnote)
                        .foregroundStyle(CT.inkSoft)
                }

                // MARK: iCloud
                Section {
                    Toggle(L.settingsIcloudToggle, isOn: Binding(
                        get: { store.iCloudEnabled },
                        set: { store.setICloudEnabled($0) }
                    ))
                } header: {
                    Text(L.settingsIcloud)
                } footer: {
                    Text(store.iCloudEnabled ? L.settingsIcloudOn : L.settingsIcloudOff)
                }

                // MARK: Data
                Section {
                    Button(L.settingsReset, role: .destructive) { showResetConfirm = true }
                } footer: {
                    Text(store.iCloudEnabled ? L.settingsResetIcloud : L.settingsLocalOnly)
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
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .confirmationDialog(L.settingsResetTitle, isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button(L.settingsDeleteAll, role: .destructive) { store.resetEverything() }
            Button(L.commonCancel, role: .cancel) {}
        } message: {
            Text(L.settingsResetMsg)
        }
    }

    private func cupLabel(_ cup: WaterCup) -> some View {
        HStack {
            Label {
                Text(cup.kind.title)
            } icon: {
                CupIcon(kind: cup.kind).fill(CT.accent).frame(width: 20, height: 20)
            }
            Spacer()
            Text(verbatim: "\(cup.ml) ml")
                .foregroundStyle(CT.inkSoft)
            if !plus.isUnlocked {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(CT.gold)
            }
        }
    }

    /// Akıllı hatırlatma OneScoop+'a özel: Plus yoksa satın alma ekranı açılır.
    private func setWaterReminder(_ mode: WaterReminderMode) {
        if mode == .smart && !plus.isUnlocked {
            showPaywall = true
            return
        }
        store.updateWater { $0.reminderMode = mode }
        if mode != .off { requestPermissionIfNeeded() }
    }

    private func requestPermissionIfNeeded() {
        Task {
            let status = await NotificationManager.authorizationStatus()
            if status == .notDetermined {
                _ = await NotificationManager.requestAuthorization()
            }
            permissionDenied = await NotificationManager.authorizationStatus() == .denied
            await NotificationManager.reschedule()
            await WaterReminders.reschedule()
        }
    }
}

extension View {
    /// OneScoop+ özelliği: Plus varsa kontrolün kendisi, yoksa dokununca
    /// satın alma ekranını açan bir satır.
    @ViewBuilder
    func plusGated<Locked: View>(
        _ unlocked: Bool,
        onLockedTap: @escaping () -> Void,
        @ViewBuilder locked: () -> Locked
    ) -> some View {
        if unlocked {
            self
        } else {
            Button(action: onLockedTap) { locked() }
                .foregroundStyle(CT.ink)
        }
    }
}
