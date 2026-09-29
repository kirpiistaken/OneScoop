import SwiftUI
import UserNotifications

// Ayarlar sade tutuluyor: ana ekranda birkaç satır, detaylar alt sayfalarda.
//
//   OneScoop+
//   Kreatin ›        doz, yükleme fazı, hatırlatma
//   Su ›             hedef, kaplar, hatırlatma, Apple Sağlık
//   Uygulama ikonu
//   iCloud
//   Veriler ›        dışa aktar, sıfırla
//   (Test — sadece TestFlight)

struct SettingsView: View {
    @EnvironmentObject private var store: CreatineStore
    @EnvironmentObject private var plus: PlusStore
    @State private var showPaywall = false
    @State private var showIconPicker = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: OneScoop+
                Section {
                    Button { showPaywall = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(CT.gold)
                                .frame(width: 36, height: 36)
                                .background(CT.goldSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                PlusWordmark(size: 17)
                                if !plus.isUnlocked {
                                    Text(L.settingsPlusSubtitle)
                                        .font(.footnote)
                                        .foregroundStyle(CT.inkSoft)
                                }
                            }
                            Spacer()
                            if plus.isUnlocked {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(CT.accent)
                            } else {
                                chevron
                            }
                        }
                    }
                }

                // MARK: Kreatin ve su
                Section {
                    NavigationLink {
                        CreatineSettingsView()
                    } label: {
                        row(L.historyCreatine, detail: creatineDetail) {
                            ScoopShape().fill(CT.accent).frame(width: 20, height: 20)
                        }
                    }
                    NavigationLink {
                        WaterSettingsView()
                    } label: {
                        row(L.settingsWater, detail: waterDetail) {
                            CupIcon(kind: .glass).fill(CT.accent).frame(width: 18, height: 18)
                        }
                    }
                }

                // MARK: Görünüm ve yedek
                Section {
                    Button { showIconPicker = true } label: {
                        HStack {
                            row(L.settingsAppIcon, detail: AppIconOption.current.title) {
                                Image(systemName: "app.badge.fill").foregroundStyle(CT.accent)
                            }
                            chevron
                        }
                    }
                    Toggle(isOn: Binding(
                        get: { store.iCloudEnabled },
                        set: { store.setICloudEnabled($0) }
                    )) {
                        row(L.settingsIcloudToggle, detail: nil) {
                            Image(systemName: "icloud.fill").foregroundStyle(CT.accent)
                        }
                    }
                } footer: {
                    Text(store.iCloudEnabled ? L.settingsIcloudOn : L.settingsIcloudOff)
                }

                // MARK: Veriler
                Section {
                    NavigationLink {
                        DataSettingsView()
                    } label: {
                        row(L.settingsData, detail: nil) {
                            Image(systemName: "externaldrive.fill").foregroundStyle(CT.accent)
                        }
                    }
                }

                // MARK: Test (sadece TestFlight)
                if plus.isTestBuild {
                    Section {
                        HStack {
                            Text(verbatim: "OneScoop+")
                            Spacer()
                            Text(plus.isUnlocked ? L.settingsTestPlusOn : L.settingsTestPlusOff)
                                .foregroundStyle(plus.isUnlocked ? CT.gold : CT.inkSoft)
                        }
                        if plus.simulated {
                            Button(L.settingsTestCancel, role: .destructive) {
                                Task { await plus.cancelSimulatedPurchase() }
                            }
                        } else {
                            Button(L.settingsTestOpenPaywall) { showPaywall = true }
                        }
                    } header: {
                        Label(L.settingsTest, systemImage: "hammer.fill")
                    } footer: {
                        Text(L.settingsTestFooter)
                    }
                }
            }
            .navigationTitle(L.tabSettings)
            .scrollContentBackground(.hidden)
            .background(CT.bg)
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showIconPicker) { AppIconPicker() }
    }

    private var creatineDetail: String {
        let dose = "\(store.settings.maintenanceDose.gramString) g"
        return store.settings.reminderEnabled
            ? "\(dose) · \(store.settings.reminderTimeLocalized)"
            : dose
    }

    private var waterDetail: String {
        store.water.enabled ? "\(store.water.goalMl.litersString) L" : L.settingsWaterRemindOff
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(CT.inkSoft.opacity(0.6))
    }

    private func row<Icon: View>(_ title: String, detail: String?, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 12) {
            icon().frame(width: 24)
            Text(title).foregroundStyle(CT.ink)
            Spacer()
            if let detail {
                Text(verbatim: detail)
                    .foregroundStyle(CT.inkSoft)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Bildirim izni (kreatin ve su ortak)

enum NotificationPermission {
    /// Gerekirse izin ister, bildirimleri yeniden kurar. İzin reddedildiyse `true`.
    static func requestIfNeeded() async -> Bool {
        if await NotificationManager.authorizationStatus() == .notDetermined {
            _ = await NotificationManager.requestAuthorization()
        }
        await NotificationManager.reschedule()
        await WaterReminders.reschedule()
        return await NotificationManager.authorizationStatus() == .denied
    }
}

// MARK: - Kreatin

struct CreatineSettingsView: View {
    @EnvironmentObject private var store: CreatineStore
    @State private var reminderTime = Date()
    @State private var permissionDenied = false

    private let intervalOptions = [15, 30, 60, 120]

    private func intervalLabel(_ minutes: Int) -> String {
        minutes < 60 ? L.settingsMinutes(minutes) : L.settingsHours(minutes / 60)
    }

    var body: some View {
        Form {
            // Doz ve yükleme fazı
            Section {
                Stepper(value: Binding(
                    get: { store.settings.maintenanceDose },
                    set: { new in store.update { $0.maintenanceDose = new } }
                ), in: 1...15, step: 0.5) {
                    valueRow(L.onbDailyDose, "\(store.settings.maintenanceDose.gramString) g")
                }

                Toggle(L.settingsLoadingPhase, isOn: Binding(
                    get: { store.settings.usesLoadingPhase },
                    set: { new in store.update { $0.usesLoadingPhase = new } }
                ))

                if store.settings.usesLoadingPhase {
                    Stepper(value: Binding(
                        get: { store.settings.loadingDose },
                        set: { new in store.update { $0.loadingDose = new } }
                    ), in: 5...30, step: 1) {
                        valueRow(L.settingsLoadingDose, "\(store.settings.loadingDose.gramString) g")
                    }
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
            } header: {
                Text(L.settingsDose)
            } footer: {
                if store.settings.usesLoadingPhase {
                    Text(L.settingsLoadingFooter(store.settings.loadingDaysRemaining))
                }
            }

            // Hatırlatma (tekrar dahil, tek grupta)
            Section {
                Toggle(L.onbReminder, isOn: Binding(
                    get: { store.settings.reminderEnabled },
                    set: { new in
                        store.update { $0.reminderEnabled = new }
                        if new { askPermission() }
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
                }
            } header: {
                Text(L.settingsNotifications)
            } footer: {
                if permissionDenied {
                    Text(L.settingsDenied)
                } else if store.settings.reminderEnabled {
                    Text(L.settingsOnlyUnlogged)
                }
            }
        }
        .navigationTitle(L.historyCreatine)
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(CT.bg)
        .task {
            reminderTime = Calendar.current.date(
                from: DateComponents(hour: store.settings.reminderHour, minute: store.settings.reminderMinute)
            ) ?? Date()
            permissionDenied = await NotificationManager.authorizationStatus() == .denied
        }
    }

    private func askPermission() {
        Task { permissionDenied = await NotificationPermission.requestIfNeeded() }
    }
}

// MARK: - Su

struct WaterSettingsView: View {
    @EnvironmentObject private var store: CreatineStore
    @EnvironmentObject private var plus: PlusStore
    @State private var showPaywall = false
    @State private var permissionDenied = false

    var body: some View {
        Form {
            // Aç/kapa ve hedef
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
                        valueRow(L.settingsWaterGoal, "\(store.water.goalMl.litersString) L")
                    }
                }
            } footer: {
                if store.water.enabled { Text(L.settingsWaterFooter) }
            }

            if store.water.enabled {
                // Kaplar ve varsayılan kap
                Section {
                    ForEach(Array(store.water.cups.enumerated()), id: \.element.id) { index, cup in
                        Stepper(value: Binding(
                            get: { cup.ml },
                            set: { new in store.updateWater { $0.cups[index].ml = new } }
                        ), in: 100...1500, step: 50) {
                            HStack {
                                Label {
                                    Text(cup.kind.title)
                                } icon: {
                                    CupIcon(kind: cup.kind).fill(CT.accent).frame(width: 20, height: 20)
                                }
                                Spacer()
                                Text(verbatim: "\(cup.ml) ml").foregroundStyle(CT.inkSoft)
                            }
                        }
                    }
                    Picker(L.settingsWaterDefault, selection: Binding(
                        get: { store.water.defaultCup.id },
                        set: { new in store.updateWater { $0.defaultCupID = new } }
                    )) {
                        ForEach(store.water.cups) { cup in
                            Text(verbatim: cup.kind.title).tag(cup.id)
                        }
                    }
                } header: {
                    Text(L.settingsWaterCups)
                }

                // Hatırlatma
                Section {
                    Picker(L.settingsWaterReminders, selection: Binding(
                        get: { store.water.reminderMode },
                        set: { new in setReminder(new) }
                    )) {
                        Text(L.settingsWaterRemindOff).tag(WaterReminderMode.off)
                        Text(L.settingsWaterRemindSimple).tag(WaterReminderMode.simple)
                        // Taç yazının sağında (OneScoop+).
                        Text("\(L.settingsWaterRemindSmart) \(Image(systemName: "crown.fill"))")
                            .tag(WaterReminderMode.smart)
                    }

                    // Gün saatleri sadece basitte; akıllı kendisi öğreniyor.
                    if store.water.reminderMode == .simple {
                        Stepper(value: Binding(
                            get: { store.water.simpleIntervalHours },
                            set: { new in store.updateWater { $0.simpleIntervalHours = new } }
                        ), in: 1...4) {
                            Text(L.settingsWaterEvery(store.water.simpleIntervalHours))
                        }
                        Stepper(value: Binding(
                            get: { store.water.wakeHour },
                            set: { new in store.updateWater { $0.wakeHour = new } }
                        ), in: 5...12) {
                            valueRow(L.settingsWaterDayStart, String(format: "%02d:00", store.water.wakeHour))
                        }
                        Stepper(value: Binding(
                            get: { store.water.sleepHour },
                            set: { new in store.updateWater { $0.sleepHour = new } }
                        ), in: 18...23) {
                            valueRow(L.settingsWaterDayEnd, String(format: "%02d:00", store.water.sleepHour))
                        }
                    }
                } header: {
                    Text(L.settingsNotifications)
                } footer: {
                    reminderFooter
                }

                // Apple Sağlık (OneScoop+)
                if HealthSync.isAvailable {
                    Section {
                        Toggle(isOn: Binding(
                            get: { store.water.healthEnabled && plus.isUnlocked },
                            set: { new in
                                guard plus.isUnlocked else { showPaywall = true; return }
                                Task { await store.setHealthEnabled(new) }
                            }
                        )) {
                            HStack(spacing: 6) {
                                Text(L.settingsWaterHealth)
                                if !plus.isUnlocked { crown }
                            }
                        }

                        if store.water.healthEnabled && plus.isUnlocked {
                            Toggle(L.settingsWaterWorkout, isOn: Binding(
                                get: { store.water.workoutBoostEnabled },
                                set: { new in Task { await store.setWorkoutBoost(new) } }
                            ))
                            if store.water.workoutBoostEnabled {
                                Stepper(value: Binding(
                                    get: { store.water.workoutBoostMl },
                                    set: { new in store.updateWater { $0.workoutBoostMl = new } }
                                ), in: 250...1500, step: 250) {
                                    valueRow(L.settingsWaterWorkoutExtra, "+\(store.water.workoutBoostMl) ml")
                                }
                            }
                        }
                    } footer: {
                        if store.water.healthEnabled && plus.isUnlocked {
                            Text(L.settingsWaterHealthFooter)
                        }
                    }
                }
            }
        }
        .navigationTitle(L.settingsWater)
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(CT.bg)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .task { permissionDenied = await NotificationManager.authorizationStatus() == .denied }
    }

    @ViewBuilder
    private var reminderFooter: some View {
        if permissionDenied && store.water.reminderMode != .off {
            Text(L.settingsDenied)
        } else {
            switch store.water.reminderMode {
            case .off:
                EmptyView()
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

    private var crown: some View {
        Image(systemName: "crown.fill")
            .font(.caption)
            .foregroundStyle(CT.gold)
    }

    /// Akıllı hatırlatma OneScoop+'a özel: Plus yoksa satın alma ekranı açılır.
    private func setReminder(_ mode: WaterReminderMode) {
        if mode == .smart && !plus.isUnlocked {
            showPaywall = true
            return
        }
        store.updateWater { $0.reminderMode = mode }
        if mode != .off {
            Task { permissionDenied = await NotificationPermission.requestIfNeeded() }
        }
    }
}

// MARK: - Veriler

struct DataSettingsView: View {
    @EnvironmentObject private var store: CreatineStore
    @EnvironmentObject private var plus: PlusStore
    @State private var showPaywall = false
    @State private var showResetConfirm = false
    @State private var exportFile: ExportFile?

    var body: some View {
        Form {
            Section {
                Button {
                    guard plus.isUnlocked else { showPaywall = true; return }
                    if let url = DataExport.makeCSV() { exportFile = ExportFile(url: url) }
                } label: {
                    HStack {
                        Label(L.settingsExport, systemImage: "square.and.arrow.up")
                            .foregroundStyle(CT.ink)
                        Spacer()
                        if !plus.isUnlocked {
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(CT.gold)
                        }
                    }
                }
            } footer: {
                Text(L.settingsExportFooter)
            }

            Section {
                Button(L.settingsReset, role: .destructive) { showResetConfirm = true }
            } footer: {
                Text(store.iCloudEnabled ? L.settingsResetIcloud : L.settingsLocalOnly)
            }
        }
        .navigationTitle(L.settingsData)
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(CT.bg)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(item: $exportFile) { ShareSheet(url: $0.url) }
        .confirmationDialog(L.settingsResetTitle, isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button(L.settingsDeleteAll, role: .destructive) { store.resetEverything() }
            Button(L.commonCancel, role: .cancel) {}
        } message: {
            Text(L.settingsResetMsg)
        }
    }
}

// MARK: - Ortak

/// "Başlık ........ değer" satırı (Stepper etiketi olarak).
private func valueRow(_ title: String, _ value: String) -> some View {
    HStack {
        Text(title)
        Spacer()
        Text(verbatim: value).foregroundStyle(CT.inkSoft)
    }
}
