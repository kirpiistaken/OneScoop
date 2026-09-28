// ⚠️ Bu dosya otomatik üretildi (l10n_build.py). Elle düzenleme.
// Yeni metin eklerken tabloya ekle ve betiği yeniden çalıştır.
import Foundation

enum L {
    static var commonCancel: String { String(localized: "common.cancel") }
    static var complicationDescription: String { String(localized: "complication.description") }
    static var complicationNotYet: String { String(localized: "complication.not_yet") }
    static var controlDescription: String { String(localized: "control.description") }
    static var historyDayStreak: String { String(localized: "history.day_streak") }
    static var historyDaysLogged: String { String(localized: "history.days_logged") }
    static var historyLoading: String { String(localized: "history.loading") }
    static var historyMaintenance: String { String(localized: "history.maintenance") }
    static var historyTapHint: String { String(localized: "history.tap_hint") }
    static var historyThisMonth: String { String(localized: "history.this_month") }
    static var insightConsistent: String { String(localized: "insight.consistent") }
    static func insightEmpty(_ a0: String) -> String { String(localized: "insight.empty \(a0)") }
    static func insightLoading(_ a0: Int, _ a1: String, _ a2: String) -> String { String(localized: "insight.loading \(a0) \(a1) \(a2)") }
    static var insightMissed: String { String(localized: "insight.missed") }
    static func insightStreak(_ a0: Int) -> String { String(localized: "insight.streak \(a0)") }
    static func insightSummary(_ a0: Int, _ a1: Int, _ a2: String, _ a3: String, _ a4: String) -> String { String(localized: "insight.summary \(a0) \(a1) \(a2) \(a3) \(a4)") }
    static var notifFirst: String { String(localized: "notif.first") }
    static var notifLogIt: String { String(localized: "notif.log_it") }
    static var notifRepeat: String { String(localized: "notif.repeat") }
    static var onbDailyDose: String { String(localized: "onb.daily_dose") }
    static var onbDoseHint: String { String(localized: "onb.dose_hint") }
    static func onbLoadingForDays(_ a0: Int) -> String { String(localized: "onb.loading_for_days \(a0)") }
    static func onbLoadingSummary(_ a0: String, _ a1: Int, _ a2: String, _ a3: Int) -> String { String(localized: "onb.loading_summary \(a0) \(a1) \(a2) \(a3)") }
    static var onbLoadingToggle: String { String(localized: "onb.loading_toggle") }
    static var onbReminder: String { String(localized: "onb.reminder") }
    static var onbReminderHint: String { String(localized: "onb.reminder_hint") }
    static var onbStart: String { String(localized: "onb.start") }
    static var onbTagline: String { String(localized: "onb.tagline") }
    static var restoreChecking: String { String(localized: "restore.checking") }
    static var settingsAdjust: String { String(localized: "settings.adjust") }
    static var settingsAdjustLoading: String { String(localized: "settings.adjust_loading") }
    static var settingsDeleteAll: String { String(localized: "settings.delete_all") }
    static var settingsDenied: String { String(localized: "settings.denied") }
    static var settingsDose: String { String(localized: "settings.dose") }
    static var settingsEvery: String { String(localized: "settings.every") }
    static func settingsHours(_ a0: Int) -> String { String(localized: "settings.hours \(a0)") }
    static var settingsIcloud: String { String(localized: "settings.icloud") }
    static var settingsIcloudOff: String { String(localized: "settings.icloud_off") }
    static var settingsIcloudOn: String { String(localized: "settings.icloud_on") }
    static var settingsIcloudToggle: String { String(localized: "settings.icloud_toggle") }
    static func settingsLength(_ a0: Int) -> String { String(localized: "settings.length \(a0)") }
    static var settingsLoadingDose: String { String(localized: "settings.loading_dose") }
    static func settingsLoadingFooter(_ a0: Int) -> String { String(localized: "settings.loading_footer \(a0)") }
    static var settingsLoadingPhase: String { String(localized: "settings.loading_phase") }
    static var settingsLocalOnly: String { String(localized: "settings.local_only") }
    static func settingsMinutes(_ a0: Int) -> String { String(localized: "settings.minutes \(a0)") }
    static var settingsNotifications: String { String(localized: "settings.notifications") }
    static var settingsOnlyUnlogged: String { String(localized: "settings.only_unlogged") }
    static var settingsRemindAgain: String { String(localized: "settings.remind_again") }
    static var settingsRepeat: String { String(localized: "settings.repeat") }
    static var settingsRepeatFooterOff: String { String(localized: "settings.repeat_footer_off") }
    static func settingsRepeatFooterOn(_ a0: String, _ a1: String) -> String { String(localized: "settings.repeat_footer_on \(a0) \(a1)") }
    static var settingsReset: String { String(localized: "settings.reset") }
    static var settingsResetIcloud: String { String(localized: "settings.reset_icloud") }
    static var settingsResetMsg: String { String(localized: "settings.reset_msg") }
    static var settingsResetTitle: String { String(localized: "settings.reset_title") }
    static var settingsStartedOn: String { String(localized: "settings.started_on") }
    static var settingsTime: String { String(localized: "settings.time") }
    static func settingsUpTo(_ a0: Int) -> String { String(localized: "settings.up_to \(a0)") }
    static var settingsWidget: String { String(localized: "settings.widget") }
    static var settingsWidgetHelp: String { String(localized: "settings.widget_help") }
    static var shortcutLog: String { String(localized: "shortcut.log") }
    static var supplyCorrect: String { String(localized: "supply.correct") }
    static var supplyDaysLeft: String { String(localized: "supply.days_left") }
    static var supplyEmptyBody: String { String(localized: "supply.empty_body") }
    static var supplyEmptyTitle: String { String(localized: "supply.empty_title") }
    static var supplyGLeft: String { String(localized: "supply.g_left") }
    static func supplyLow(_ a0: Int) -> String { String(localized: "supply.low \(a0)") }
    static var supplyNewContainer: String { String(localized: "supply.new_container") }
    static func supplyOfContainer(_ a0: String) -> String { String(localized: "supply.of_container \(a0)") }
    static var supplyOut: String { String(localized: "supply.out") }
    static var supplyPerDay: String { String(localized: "supply.per_day") }
    static func supplyRemaining(_ a0: String) -> String { String(localized: "supply.remaining \(a0)") }
    static var supplyRunsOut: String { String(localized: "supply.runs_out") }
    static var supplySetup: String { String(localized: "supply.setup") }
    static var supplySheetHint: String { String(localized: "supply.sheet_hint") }
    static var supplySheetQ: String { String(localized: "supply.sheet_q") }
    static var supplySheetStart: String { String(localized: "supply.sheet_start") }
    static var supplyTurnOff: String { String(localized: "supply.turn_off") }
    static var tabHistory: String { String(localized: "tab.history") }
    static var tabSettings: String { String(localized: "tab.settings") }
    static var tabSupply: String { String(localized: "tab.supply") }
    static var tabToday: String { String(localized: "tab.today") }
    static var todayDoneTitle: String { String(localized: "today.done_title") }
    static func todayDose(_ a0: String) -> String { String(localized: "today.dose \(a0)") }
    static func todayLoadingLeft(_ a0: Int) -> String { String(localized: "today.loading_left \(a0)") }
    static func todayLoggedAt(_ a0: String, _ a1: String) -> String { String(localized: "today.logged_at \(a0) \(a1)") }
    static var todayQuestion: String { String(localized: "today.question") }
    static func todayReminderSet(_ a0: String) -> String { String(localized: "today.reminder_set \(a0)") }
    static var todaySeeYou: String { String(localized: "today.see_you") }
    static func todayStreak(_ a0: Int) -> String { String(localized: "today.streak \(a0)") }
    static var todayUndo: String { String(localized: "today.undo") }
    static var todayYes: String { String(localized: "today.yes") }
    static var todayYesA11y: String { String(localized: "today.yes_a11y") }
    static var watchSetupFirst: String { String(localized: "watch.setup_first") }
    static var widgetDescription: String { String(localized: "widget.description") }
    static var widgetDoseLogged: String { String(localized: "widget.dose_logged") }
    static func widgetGramsToday(_ a0: String) -> String { String(localized: "widget.grams_today \(a0)") }
    static func widgetStreak(_ a0: Int) -> String { String(localized: "widget.streak \(a0)") }
}
