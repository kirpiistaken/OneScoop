// ⚠️ Bu dosya otomatik üretildi (l10n_build.py). Elle düzenleme.
// Yeni metin eklerken tabloya ekle ve betiği yeniden çalıştır.
import Foundation

enum L {
    static var badgeC100: String { String(localized: "badge.c100") }
    static var badgeC30: String { String(localized: "badge.c30") }
    static var badgeC365: String { String(localized: "badge.c365") }
    static var badgeC7: String { String(localized: "badge.c7") }
    static var badgeContainer: String { String(localized: "badge.container") }
    static var badgeContainerDetail: String { String(localized: "badge.container_detail") }
    static func badgeCreatineDetail(_ a0: Int) -> String { String(localized: "badge.creatine_detail \(a0)") }
    static var badgeFirst: String { String(localized: "badge.first") }
    static var badgeFirstDetail: String { String(localized: "badge.first_detail") }
    static var badgeLoading: String { String(localized: "badge.loading") }
    static var badgeLoadingDetail: String { String(localized: "badge.loading_detail") }
    static var badgeMonth: String { String(localized: "badge.month") }
    static var badgeMonthDetail: String { String(localized: "badge.month_detail") }
    static var badgeW100: String { String(localized: "badge.w100") }
    static var badgeW30: String { String(localized: "badge.w30") }
    static var badgeW365: String { String(localized: "badge.w365") }
    static var badgeW7: String { String(localized: "badge.w7") }
    static func badgeWaterDetail(_ a0: Int) -> String { String(localized: "badge.water_detail \(a0)") }
    static var badgesAll: String { String(localized: "badges.all") }
    static var badgesAllStreaks: String { String(localized: "badges.all_streaks") }
    static func badgesDaysLeft(_ a0: Int) -> String { String(localized: "badges.days_left \(a0)") }
    static func badgesEarned(_ a0: Int, _ a1: Int) -> String { String(localized: "badges.earned \(a0) \(a1)") }
    static func badgesEarnedOn(_ a0: String) -> String { String(localized: "badges.earned_on \(a0)") }
    static func badgesNext(_ a0: String) -> String { String(localized: "badges.next \(a0)") }
    static var badgesRuleNote: String { String(localized: "badges.rule_note") }
    static var badgesTitle: String { String(localized: "badges.title") }
    static var calcApplied: String { String(localized: "calc.applied") }
    static var calcApply: String { String(localized: "calc.apply") }
    static var calcBase: String { String(localized: "calc.base") }
    static func calcCreatine(_ a0: String) -> String { String(localized: "calc.creatine \(a0)") }
    static var calcDisclaimer: String { String(localized: "calc.disclaimer") }
    static var calcDose: String { String(localized: "calc.dose") }
    static var calcFromHealth: String { String(localized: "calc.from_health") }
    static func calcGlasses(_ a0: Int) -> String { String(localized: "calc.glasses \(a0)") }
    static func calcMyDose(_ a0: String) -> String { String(localized: "calc.my_dose \(a0)") }
    static var calcResultLabel: String { String(localized: "calc.result_label") }
    static var calcTitle: String { String(localized: "calc.title") }
    static var calcWeight: String { String(localized: "calc.weight") }
    static var calcWorkout: String { String(localized: "calc.workout") }
    static func celebrateMany(_ a0: Int) -> String { String(localized: "celebrate.many \(a0)") }
    static var celebrateOne: String { String(localized: "celebrate.one") }
    static var commonCancel: String { String(localized: "common.cancel") }
    static var commonDone: String { String(localized: "common.done") }
    static var complicationDescription: String { String(localized: "complication.description") }
    static var complicationNotYet: String { String(localized: "complication.not_yet") }
    static var controlDescription: String { String(localized: "control.description") }
    static var controlWaterDesc: String { String(localized: "control.water_desc") }
    static var historyCreatine: String { String(localized: "history.creatine") }
    static var historyDayStreak: String { String(localized: "history.day_streak") }
    static var historyDaysLogged: String { String(localized: "history.days_logged") }
    static var historyLoading: String { String(localized: "history.loading") }
    static var historyMaintenance: String { String(localized: "history.maintenance") }
    static var historyTapHint: String { String(localized: "history.tap_hint") }
    static var historyThisMonth: String { String(localized: "history.this_month") }
    static var historyWaterAverage: String { String(localized: "history.water_average") }
    static var historyWaterGoalDays: String { String(localized: "history.water_goal_days") }
    static var historyWaterHint: String { String(localized: "history.water_hint") }
    static var iconClassic: String { String(localized: "icon.classic") }
    static var iconGold: String { String(localized: "icon.gold") }
    static var iconLight: String { String(localized: "icon.light") }
    static var iconNight: String { String(localized: "icon.night") }
    static var insightConsistent: String { String(localized: "insight.consistent") }
    static func insightEmpty(_ a0: String) -> String { String(localized: "insight.empty \(a0)") }
    static func insightLoading(_ a0: Int, _ a1: String, _ a2: String) -> String { String(localized: "insight.loading \(a0) \(a1) \(a2)") }
    static var insightMissed: String { String(localized: "insight.missed") }
    static func insightStreak(_ a0: Int) -> String { String(localized: "insight.streak \(a0)") }
    static func insightSummary(_ a0: Int, _ a1: Int, _ a2: String, _ a3: String, _ a4: String) -> String { String(localized: "insight.summary \(a0) \(a1) \(a2) \(a3) \(a4)") }
    static func insightsAverage(_ a0: String) -> String { String(localized: "insights.average \(a0)") }
    static func insightsCreatine(_ a0: Int, _ a1: Int) -> String { String(localized: "insights.creatine \(a0) \(a1)") }
    static func insightsGoalDays(_ a0: Int, _ a1: Int) -> String { String(localized: "insights.goal_days \(a0) \(a1)") }
    static var insightsNoWater: String { String(localized: "insights.no_water") }
    static func insightsPeak(_ a0: String) -> String { String(localized: "insights.peak \(a0)") }
    static var insightsQuietAfternoon: String { String(localized: "insights.quiet_afternoon") }
    static var insightsQuietEvening: String { String(localized: "insights.quiet_evening") }
    static var insightsQuietMorning: String { String(localized: "insights.quiet_morning") }
    static var insightsTitle: String { String(localized: "insights.title") }
    static var notifAfterWorkout: String { String(localized: "notif.after_workout") }
    static var notifFirst: String { String(localized: "notif.first") }
    static var notifLogIt: String { String(localized: "notif.log_it") }
    static var notifRepeat: String { String(localized: "notif.repeat") }
    static var notifSupplyLow: String { String(localized: "notif.supply_low") }
    static func notifWaterPace(_ a0: String) -> String { String(localized: "notif.water_pace \(a0)") }
    static var notifWaterSimple: String { String(localized: "notif.water_simple") }
    static func notifWaterSmart(_ a0: String, _ a1: String) -> String { String(localized: "notif.water_smart \(a0) \(a1)") }
    static var onbDailyDose: String { String(localized: "onb.daily_dose") }
    static var onbDoseHint: String { String(localized: "onb.dose_hint") }
    static func onbLoadingForDays(_ a0: Int) -> String { String(localized: "onb.loading_for_days \(a0)") }
    static func onbLoadingSummary(_ a0: String, _ a1: Int, _ a2: String, _ a3: Int) -> String { String(localized: "onb.loading_summary \(a0) \(a1) \(a2) \(a3)") }
    static var onbLoadingToggle: String { String(localized: "onb.loading_toggle") }
    static var onbReminder: String { String(localized: "onb.reminder") }
    static var onbReminderHint: String { String(localized: "onb.reminder_hint") }
    static var onbStart: String { String(localized: "onb.start") }
    static var onbTagline: String { String(localized: "onb.tagline") }
    static var plusBulletExport: String { String(localized: "plus.bullet_export") }
    static var plusBulletHealth: String { String(localized: "plus.bullet_health") }
    static var plusBulletIcons: String { String(localized: "plus.bullet_icons") }
    static var plusBulletInsights: String { String(localized: "plus.bullet_insights") }
    static var plusBulletReminders: String { String(localized: "plus.bullet_reminders") }
    static var plusBulletWatch: String { String(localized: "plus.bullet_watch") }
    static var plusBulletWorkout: String { String(localized: "plus.bullet_workout") }
    static var plusBuy: String { String(localized: "plus.buy") }
    static var plusFamily: String { String(localized: "plus.family") }
    static var plusHeadline: String { String(localized: "plus.headline") }
    static var plusNoSubscription: String { String(localized: "plus.no_subscription") }
    static var plusNotNow: String { String(localized: "plus.not_now") }
    static var plusRestore: String { String(localized: "plus.restore") }
    static var plusTestBuy: String { String(localized: "plus.test_buy") }
    static var plusTestMessage: String { String(localized: "plus.test_message") }
    static var plusTestNote: String { String(localized: "plus.test_note") }
    static var plusTestTitle: String { String(localized: "plus.test_title") }
    static var plusUnavailable: String { String(localized: "plus.unavailable") }
    static var plusUnlocked: String { String(localized: "plus.unlocked") }
    static var plusWidgetSubtitle: String { String(localized: "plus.widget_subtitle") }
    static var plusWidgetTitle: String { String(localized: "plus.widget_title") }
    static var reportsAverage: String { String(localized: "reports.average") }
    static func reportsAverageL(_ a0: String) -> String { String(localized: "reports.average_l \(a0)") }
    static var reportsConsistency: String { String(localized: "reports.consistency") }
    static var reportsCreatineCalendar: String { String(localized: "reports.creatine_calendar") }
    static var reportsDaily: String { String(localized: "reports.daily") }
    static func reportsDays(_ a0: Int) -> String { String(localized: "reports.days \(a0)") }
    static var reportsGoal: String { String(localized: "reports.goal") }
    static func reportsGoalDays(_ a0: Int) -> String { String(localized: "reports.goal_days \(a0)") }
    static var reportsHours: String { String(localized: "reports.hours") }
    static func reportsHoursNote(_ a0: String, _ a1: String) -> String { String(localized: "reports.hours_note \(a0) \(a1)") }
    static func reportsHoursSub(_ a0: Int) -> String { String(localized: "reports.hours_sub \(a0)") }
    static var reportsLess: String { String(localized: "reports.less") }
    static var reportsLockedButton: String { String(localized: "reports.locked_button") }
    static var reportsLockedTitle: String { String(localized: "reports.locked_title") }
    static var reportsMonth: String { String(localized: "reports.month") }
    static var reportsRolling: String { String(localized: "reports.rolling") }
    static var reportsSameAsBefore: String { String(localized: "reports.same_as_before") }
    static var reportsSaturation: String { String(localized: "reports.saturation") }
    static var reportsSaturationFull: String { String(localized: "reports.saturation_full") }
    static var reportsSaturationSub: String { String(localized: "reports.saturation_sub") }
    static func reportsSaturationToFull(_ a0: Int) -> String { String(localized: "reports.saturation_to_full \(a0)") }
    static var reportsTitle: String { String(localized: "reports.title") }
    static var reportsTotalCreatine: String { String(localized: "reports.total_creatine") }
    static var reportsWaterGoal: String { String(localized: "reports.water_goal") }
    static var reportsWaterHeatmap: String { String(localized: "reports.water_heatmap") }
    static func reportsWaterSub(_ a0: String, _ a1: String) -> String { String(localized: "reports.water_sub \(a0) \(a1)") }
    static var reportsWaterTrend: String { String(localized: "reports.water_trend") }
    static var reportsWeek: String { String(localized: "reports.week") }
    static var reportsWeekday: String { String(localized: "reports.weekday") }
    static func reportsWeekdayNote(_ a0: String, _ a1: String) -> String { String(localized: "reports.weekday_note \(a0) \(a1)") }
    static var restoreChecking: String { String(localized: "restore.checking") }
    static var settingsAdjust: String { String(localized: "settings.adjust") }
    static var settingsAdjustLoading: String { String(localized: "settings.adjust_loading") }
    static var settingsAfterWorkout: String { String(localized: "settings.after_workout") }
    static var settingsAfterWorkoutFooter: String { String(localized: "settings.after_workout_footer") }
    static var settingsAppIcon: String { String(localized: "settings.app_icon") }
    static var settingsData: String { String(localized: "settings.data") }
    static var settingsDeleteAll: String { String(localized: "settings.delete_all") }
    static var settingsDenied: String { String(localized: "settings.denied") }
    static var settingsDose: String { String(localized: "settings.dose") }
    static var settingsEvery: String { String(localized: "settings.every") }
    static var settingsExport: String { String(localized: "settings.export") }
    static var settingsExportFooter: String { String(localized: "settings.export_footer") }
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
    static var settingsPlusSubtitle: String { String(localized: "settings.plus_subtitle") }
    static var settingsPortions: String { String(localized: "settings.portions") }
    static var settingsPortionsOff: String { String(localized: "settings.portions_off") }
    static var settingsRemindAgain: String { String(localized: "settings.remind_again") }
    static var settingsRepeat: String { String(localized: "settings.repeat") }
    static var settingsRepeatFooterOff: String { String(localized: "settings.repeat_footer_off") }
    static func settingsRepeatFooterOn(_ a0: String, _ a1: String) -> String { String(localized: "settings.repeat_footer_on \(a0) \(a1)") }
    static var settingsReset: String { String(localized: "settings.reset") }
    static var settingsResetIcloud: String { String(localized: "settings.reset_icloud") }
    static var settingsResetMsg: String { String(localized: "settings.reset_msg") }
    static var settingsResetTitle: String { String(localized: "settings.reset_title") }
    static var settingsStartedOn: String { String(localized: "settings.started_on") }
    static var settingsTest: String { String(localized: "settings.test") }
    static var settingsTestCancel: String { String(localized: "settings.test_cancel") }
    static var settingsTestFooter: String { String(localized: "settings.test_footer") }
    static var settingsTestOpenPaywall: String { String(localized: "settings.test_open_paywall") }
    static var settingsTestPlusOff: String { String(localized: "settings.test_plus_off") }
    static var settingsTestPlusOn: String { String(localized: "settings.test_plus_on") }
    static var settingsTestReportDemo: String { String(localized: "settings.test_report_demo") }
    static var settingsTime: String { String(localized: "settings.time") }
    static func settingsUpTo(_ a0: Int) -> String { String(localized: "settings.up_to \(a0)") }
    static var settingsWater: String { String(localized: "settings.water") }
    static var settingsWaterCups: String { String(localized: "settings.water_cups") }
    static var settingsWaterCupsFooter: String { String(localized: "settings.water_cups_footer") }
    static var settingsWaterDayEnd: String { String(localized: "settings.water_day_end") }
    static var settingsWaterDayStart: String { String(localized: "settings.water_day_start") }
    static var settingsWaterDefault: String { String(localized: "settings.water_default") }
    static func settingsWaterEvery(_ a0: Int) -> String { String(localized: "settings.water_every \(a0)") }
    static var settingsWaterFooter: String { String(localized: "settings.water_footer") }
    static var settingsWaterGoal: String { String(localized: "settings.water_goal") }
    static var settingsWaterHealth: String { String(localized: "settings.water_health") }
    static var settingsWaterHealthFooter: String { String(localized: "settings.water_health_footer") }
    static var settingsWaterRemindOff: String { String(localized: "settings.water_remind_off") }
    static var settingsWaterRemindOffFooter: String { String(localized: "settings.water_remind_off_footer") }
    static var settingsWaterRemindSimple: String { String(localized: "settings.water_remind_simple") }
    static var settingsWaterRemindSimpleFooter: String { String(localized: "settings.water_remind_simple_footer") }
    static var settingsWaterRemindSmart: String { String(localized: "settings.water_remind_smart") }
    static func settingsWaterRemindSmartLearning(_ a0: Int, _ a1: Int) -> String { String(localized: "settings.water_remind_smart_learning \(a0) \(a1)") }
    static var settingsWaterRemindSmartReady: String { String(localized: "settings.water_remind_smart_ready") }
    static var settingsWaterReminders: String { String(localized: "settings.water_reminders") }
    static var settingsWaterToggle: String { String(localized: "settings.water_toggle") }
    static var settingsWaterWorkout: String { String(localized: "settings.water_workout") }
    static var settingsWaterWorkoutExtra: String { String(localized: "settings.water_workout_extra") }
    static var settingsWidget: String { String(localized: "settings.widget") }
    static var settingsWidgetHelp: String { String(localized: "settings.widget_help") }
    static var shareButton: String { String(localized: "share.button") }
    static var shareFooter: String { String(localized: "share.footer") }
    static var shareLast4Weeks: String { String(localized: "share.last_4_weeks") }
    static var shareNewBadge: String { String(localized: "share.new_badge") }
    static var shareStreakButton: String { String(localized: "share.streak_button") }
    static var shareStreakDays: String { String(localized: "share.streak_days") }
    static var shareStreakTagline: String { String(localized: "share.streak_tagline") }
    static var shareStreakTitle: String { String(localized: "share.streak_title") }
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
    static func todayPortion(_ a0: Int, _ a1: Int, _ a2: String) -> String { String(localized: "today.portion \(a0) \(a1) \(a2)") }
    static var todayQuestion: String { String(localized: "today.question") }
    static func todayReminderSet(_ a0: String) -> String { String(localized: "today.reminder_set \(a0)") }
    static var todaySeeYou: String { String(localized: "today.see_you") }
    static func todayStreak(_ a0: Int) -> String { String(localized: "today.streak \(a0)") }
    static var todayUndo: String { String(localized: "today.undo") }
    static var todayYes: String { String(localized: "today.yes") }
    static var todayYesA11y: String { String(localized: "today.yes_a11y") }
    static var watchSetupFirst: String { String(localized: "watch.setup_first") }
    static var watchWaterAdd: String { String(localized: "watch.water_add") }
    static var watchWaterPlus: String { String(localized: "watch.water_plus") }
    static var waterCatchBottle: String { String(localized: "water.catch_bottle") }
    static var waterCatchGlass: String { String(localized: "water.catch_glass") }
    static var waterCatchShaker: String { String(localized: "water.catch_shaker") }
    static var waterCupBottle: String { String(localized: "water.cup.bottle") }
    static var waterCupGlass: String { String(localized: "water.cup.glass") }
    static var waterCupShaker: String { String(localized: "water.cup.shaker") }
    static var waterDelete: String { String(localized: "water.delete") }
    static var waterGoalReached: String { String(localized: "water.goal_reached") }
    static var waterNoEntries: String { String(localized: "water.no_entries") }
    static func waterPaceBehind(_ a0: String) -> String { String(localized: "water.pace_behind \(a0)") }
    static var waterPaceOn: String { String(localized: "water.pace_on") }
    static var waterTitle: String { String(localized: "water.title") }
    static var waterTodayEntries: String { String(localized: "water.today_entries") }
    static func waterWorkoutBoost(_ a0: String) -> String { String(localized: "water.workout_boost \(a0)") }
    static var whatsnewWaterBody: String { String(localized: "whatsnew.water_body") }
    static var whatsnewWaterTitle: String { String(localized: "whatsnew.water_title") }
    static var whatsnewWaterTry: String { String(localized: "whatsnew.water_try") }
    static var widgetDescription: String { String(localized: "widget.description") }
    static var widgetDoseLogged: String { String(localized: "widget.dose_logged") }
    static func widgetGramsToday(_ a0: String) -> String { String(localized: "widget.grams_today \(a0)") }
    static func widgetStreak(_ a0: Int) -> String { String(localized: "widget.streak \(a0)") }
    static var widgetWaterDesc: String { String(localized: "widget.water_desc") }
    static var widgetWaterName: String { String(localized: "widget.water_name") }
    static var widgetWaterOff: String { String(localized: "widget.water_off") }
    static var widgetWaterPlus: String { String(localized: "widget.water_plus") }
}
