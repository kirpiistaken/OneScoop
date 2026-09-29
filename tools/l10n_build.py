#!/usr/bin/env python3
"""
Tüm çeviriler tek tabloda. Buradan iki dosya üretiliyor:
  - Localizable.xcstrings  (Apple String Catalog)
  - L10n.swift             (koddan kullanılan erişimciler)

Böylece anahtarlar kodla çeviri dosyası arasında asla kaymıyor.
Değer bir dict ise {"one": ..., "other": ...} -> çoğul varyasyonu.
"""
import json, re, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")

LANGS = ["en", "tr", "es", "de", "fr", "it", "pt-BR"]

def P(one, other):  # çoğul
    return {"one": one, "other": other}

T = {}

def add(key, en, tr, es, de, fr, it, pt):
    T[key] = dict(zip(LANGS, [en, tr, es, de, fr, it, pt]))

# ── Sekmeler ───────────────────────────────────────────────
add("tab.today", "Today", "Bugün", "Hoy", "Heute", "Aujourd’hui", "Oggi", "Hoje")
add("tab.history", "History", "Geçmiş", "Historial", "Verlauf", "Historique", "Cronologia", "Histórico")
add("tab.supply", "Supply", "Stok", "Reserva", "Vorrat", "Stock", "Scorta", "Estoque")
add("tab.settings", "Settings", "Ayarlar", "Ajustes", "Einstellungen", "Réglages", "Impostazioni", "Ajustes")

# ── Ortak ──────────────────────────────────────────────────
add("common.cancel", "Cancel", "Vazgeç", "Cancelar", "Abbrechen", "Annuler", "Annulla", "Cancelar")

# ── Kurulum ────────────────────────────────────────────────
add("onb.tagline",
    "One tap a day. That's the whole app.",
    "Günde bir dokunuş. Uygulama bu kadar.",
    "Un toque al día. Eso es todo.",
    "Ein Tipp am Tag. Mehr ist es nicht.",
    "Un geste par jour. C’est tout.",
    "Un tocco al giorno. Tutto qui.",
    "Um toque por dia. É só isso.")
add("onb.daily_dose", "Daily dose", "Günlük doz", "Dosis diaria", "Tagesdosis", "Dose quotidienne", "Dose giornaliera", "Dose diária")
add("onb.dose_hint",
    "Most people settle around 5 g per day.",
    "Çoğu kişi günde 5 g civarında kalıyor.",
    "La mayoría se queda en unos 5 g al día.",
    "Die meisten bleiben bei etwa 5 g pro Tag.",
    "La plupart des gens s’en tiennent à environ 5 g par jour.",
    "La maggior parte delle persone si attesta intorno ai 5 g al giorno.",
    "A maioria fica em torno de 5 g por dia.")
add("onb.loading_toggle",
    "Start with a loading phase", "Yükleme fazıyla başla", "Empezar con una fase de carga",
    "Mit einer Ladephase beginnen", "Commencer par une phase de charge",
    "Inizia con una fase di carico", "Começar com uma fase de saturação")
add("onb.loading_for_days %lld",
    P("for %lld day", "for %lld days"),
    "%lld gün boyunca",
    P("durante %lld día", "durante %lld días"),
    P("für %lld Tag", "für %lld Tage"),
    P("pendant %lld jour", "pendant %lld jours"),
    P("per %lld giorno", "per %lld giorni"),
    P("por %lld dia", "por %lld dias"))
add("onb.loading_summary %@ %lld %@ %lld",
    "%1$@ g daily for %2$lld days, then %3$@ g from day %4$lld on. A loading dose this size is usually split across the day.",
    "%2$lld gün boyunca günde %1$@ g, %4$lld. günden itibaren %3$@ g. Bu büyüklükte bir yükleme dozu genelde güne yayılarak alınır.",
    "%1$@ g al día durante %2$lld días y luego %3$@ g a partir del día %4$lld. Una dosis de carga así suele repartirse a lo largo del día.",
    "%2$lld Tage lang täglich %1$@ g, danach ab Tag %4$lld %3$@ g. Eine so große Ladedosis wird meist über den Tag verteilt.",
    "%1$@ g par jour pendant %2$lld jours, puis %3$@ g à partir du jour %4$lld. Une dose de charge de cette taille se répartit généralement sur la journée.",
    "%1$@ g al giorno per %2$lld giorni, poi %3$@ g dal giorno %4$lld. Una dose di carico così si divide di solito nell’arco della giornata.",
    "%1$@ g por dia durante %2$lld dias e depois %3$@ g a partir do dia %4$lld. Uma dose de saturação desse tamanho costuma ser dividida ao longo do dia.")
add("onb.reminder", "Daily reminder", "Günlük hatırlatma", "Recordatorio diario", "Tägliche Erinnerung", "Rappel quotidien", "Promemoria giornaliero", "Lembrete diário")
add("onb.reminder_hint",
    "You'll only get a notification on days you haven't logged yet. Changeable later.",
    "Yalnızca henüz işaretlemediğin günlerde bildirim gelir. Sonradan değiştirebilirsin.",
    "Solo recibirás una notificación los días que aún no hayas registrado. Puedes cambiarlo después.",
    "Du bekommst nur an Tagen eine Mitteilung, an denen du noch nichts eingetragen hast. Später änderbar.",
    "Vous ne recevrez une notification que les jours où vous n’avez encore rien noté. Modifiable plus tard.",
    "Riceverai una notifica solo nei giorni in cui non hai ancora registrato nulla. Puoi cambiarlo in seguito.",
    "Você só recebe notificação nos dias em que ainda não registrou. Dá para mudar depois.")
add("onb.start", "Start tracking", "Takibe başla", "Empezar", "Los geht’s", "Commencer", "Inizia", "Começar")

# ── Bugün ──────────────────────────────────────────────────
add("today.loading_left %lld",
    P("Loading phase · %lld day left", "Loading phase · %lld days left"),
    "Yükleme fazı · %lld gün kaldı",
    P("Fase de carga · queda %lld día", "Fase de carga · quedan %lld días"),
    P("Ladephase · noch %lld Tag", "Ladephase · noch %lld Tage"),
    P("Phase de charge · %lld jour restant", "Phase de charge · %lld jours restants"),
    P("Fase di carico · manca %lld giorno", "Fase di carico · mancano %lld giorni"),
    P("Fase de saturação · falta %lld dia", "Fase de saturação · faltam %lld dias"))
add("today.streak %lld",
    P("%lld day streak 🔥", "%lld day streak 🔥"),
    "%lld günlük seri 🔥",
    P("Racha de %lld día 🔥", "Racha de %lld días 🔥"),
    P("%lld Tag in Folge 🔥", "%lld Tage in Folge 🔥"),
    P("%lld jour d’affilée 🔥", "%lld jours d’affilée 🔥"),
    P("%lld giorno di fila 🔥", "%lld giorni di fila 🔥"),
    P("%lld dia seguido 🔥", "%lld dias seguidos 🔥"))
add("today.question",
    "Did you take creatine today?", "Bugün kreatinini aldın mı?", "¿Tomaste creatina hoy?",
    "Hast du heute Kreatin genommen?", "Avez-vous pris votre créatine aujourd’hui ?",
    "Hai preso la creatina oggi?", "Você tomou creatina hoje?")
add("today.dose %@",
    "Today's dose: %@ g", "Bugünkü doz: %@ g", "Dosis de hoy: %@ g", "Heutige Dosis: %@ g",
    "Dose du jour : %@ g", "Dose di oggi: %@ g", "Dose de hoje: %@ g")
add("today.yes", "Yes", "Evet", "Sí", "Ja", "Oui", "Sì", "Sim")
add("today.yes_a11y",
    "Yes, I took today's creatine", "Evet, bugünkü kreatinimi aldım", "Sí, ya tomé la creatina de hoy",
    "Ja, ich habe heute Kreatin genommen", "Oui, j’ai pris ma créatine aujourd’hui",
    "Sì, ho preso la creatina di oggi", "Sim, tomei a creatina de hoje")
add("today.done_title",
    "You took your daily dose of creatine", "Günlük kreatin dozunu aldın",
    "Ya tomaste tu dosis diaria de creatina", "Du hast deine tägliche Kreatindosis genommen",
    "Vous avez pris votre dose quotidienne de créatine", "Hai preso la tua dose giornaliera di creatina",
    "Você tomou sua dose diária de creatina")
add("today.logged_at %@ %@",
    "%1$@ g · logged at %2$@", "%1$@ g · %2$@ saatinde kaydedildi", "%1$@ g · registrado a las %2$@",
    "%1$@ g · eingetragen um %2$@", "%1$@ g · noté à %2$@", "%1$@ g · registrato alle %2$@",
    "%1$@ g · registrado às %2$@")
add("today.undo", "Undo", "Geri al", "Deshacer", "Rückgängig", "Annuler", "Annulla", "Desfazer")
add("today.reminder_set %@",
    "Reminder set for %@", "Hatırlatma %@ için ayarlı", "Recordatorio a las %@", "Erinnerung um %@",
    "Rappel prévu à %@", "Promemoria alle %@", "Lembrete às %@")
add("today.see_you", "See you tomorrow.", "Yarın görüşürüz.", "Hasta mañana.", "Bis morgen.", "À demain.", "A domani.", "Até amanhã.")

# ── Geçmiş ─────────────────────────────────────────────────
add("history.maintenance", "Maintenance", "İdame", "Mantenimiento", "Erhaltung", "Entretien", "Mantenimento", "Manutenção")
add("history.loading", "Loading", "Yükleme", "Carga", "Ladephase", "Charge", "Carico", "Saturação")
add("history.days_logged", "days logged", "gün kaydedildi", "días registrados", "Tage eingetragen", "jours notés", "giorni registrati", "dias registrados")
add("history.this_month", "this month", "bu ay", "este mes", "diesen Monat", "ce mois-ci", "questo mese", "este mês")
add("history.day_streak", "day streak", "günlük seri", "días de racha", "Tage in Folge", "jours d’affilée", "giorni di fila", "dias seguidos")
add("history.tap_hint",
    "Tap any past day to add or remove an entry.",
    "Kayıt eklemek ya da silmek için geçmiş bir güne dokun.",
    "Toca cualquier día pasado para añadir o quitar un registro.",
    "Tippe auf einen vergangenen Tag, um einen Eintrag hinzuzufügen oder zu entfernen.",
    "Touchez un jour passé pour ajouter ou supprimer une entrée.",
    "Tocca un giorno passato per aggiungere o rimuovere una voce.",
    "Toque em um dia anterior para adicionar ou remover um registro.")

# ── Takvim özeti ───────────────────────────────────────────
add("insight.empty %@",
    "No doses logged in %@ yet. Tap Yes on the Today tab once you take today's dose.",
    "%@ ayında henüz kayıt yok. Bugünkü dozunu aldığında Bugün sekmesinde Evet'e dokun.",
    "Aún no hay dosis registradas en %@. Toca Sí en la pestaña Hoy cuando tomes la de hoy.",
    "Im %@ ist noch keine Dosis eingetragen. Tippe im Tab „Heute“ auf Ja, sobald du die heutige genommen hast.",
    "Aucune dose notée en %@ pour l’instant. Touchez Oui dans l’onglet Aujourd’hui après avoir pris celle du jour.",
    "Nessuna dose registrata a %@ finora. Tocca Sì nella scheda Oggi quando prendi quella di oggi.",
    "Nenhuma dose registrada em %@ ainda. Toque em Sim na aba Hoje depois de tomar a de hoje.")
add("insight.summary %lld %lld %@ %@ %@",
    "%1$lld of %2$lld days in %3$@ — %4$@ g total, %5$@ consistency.",
    "%3$@: %2$lld günden %1$lld gün — toplam %4$@ g, tutarlılık %5$@.",
    "%1$lld de %2$lld días en %3$@ — %4$@ g en total, %5$@ de constancia.",
    "%1$lld von %2$lld Tagen im %3$@ — insgesamt %4$@ g, %5$@ Konstanz.",
    "%1$lld jours sur %2$lld en %3$@ — %4$@ g au total, %5$@ de régularité.",
    "%1$lld giorni su %2$lld a %3$@ — %4$@ g in totale, %5$@ di costanza.",
    "%1$lld de %2$lld dias em %3$@ — %4$@ g no total, %5$@ de constância.")
add("insight.streak %lld",
    P("You're on a %lld-day streak.", "You're on a %lld-day streak."),
    "%lld günlük serin var.",
    P("Llevas una racha de %lld día.", "Llevas una racha de %lld días."),
    P("Du bist %lld Tag in Folge dabei.", "Du bist %lld Tage in Folge dabei."),
    P("Vous en êtes à %lld jour d’affilée.", "Vous en êtes à %lld jours d’affilée."),
    P("Sei a %lld giorno di fila.", "Sei a %lld giorni di fila."),
    P("Você está há %lld dia seguido.", "Você está há %lld dias seguidos."))
add("insight.loading %lld %@ %@",
    "Loading days left: %1$lld (%2$@ g), then %3$@ g daily.",
    "Kalan yükleme günü: %1$lld (%2$@ g), sonra günde %3$@ g.",
    "Días de carga restantes: %1$lld (%2$@ g), luego %3$@ g al día.",
    "Verbleibende Ladetage: %1$lld (%2$@ g), danach täglich %3$@ g.",
    "Jours de charge restants : %1$lld (%2$@ g), puis %3$@ g par jour.",
    "Giorni di carico rimanenti: %1$lld (%2$@ g), poi %3$@ g al giorno.",
    "Dias de saturação restantes: %1$lld (%2$@ g), depois %3$@ g por dia.")
add("insight.consistent",
    "Four weeks straight. At this point it's just part of your routine.",
    "Dört hafta aralıksız. Artık rutininin bir parçası.",
    "Cuatro semanas seguidas. Ya forma parte de tu rutina.",
    "Vier Wochen am Stück. Das gehört jetzt einfach zu deiner Routine.",
    "Quatre semaines d’affilée. C’est désormais une habitude.",
    "Quattro settimane di fila. Ormai fa parte della tua routine.",
    "Quatro semanas seguidas. Já faz parte da sua rotina.")
add("insight.missed",
    "A few days slipped this month. Turning on a reminder usually helps.",
    "Bu ay birkaç gün kaçtı. Hatırlatmayı açmak genelde işe yarar.",
    "Este mes se te pasaron algunos días. Activar un recordatorio suele ayudar.",
    "Diesen Monat sind ein paar Tage ausgefallen. Eine Erinnerung hilft meistens.",
    "Quelques jours ont été oubliés ce mois-ci. Activer un rappel aide généralement.",
    "Questo mese hai saltato qualche giorno. Attivare un promemoria di solito aiuta.",
    "Alguns dias passaram batido este mês. Ativar um lembrete costuma ajudar.")

# ── Ayarlar ────────────────────────────────────────────────
add("settings.dose", "Dose", "Doz", "Dosis", "Dosis", "Dose", "Dose", "Dose")
add("settings.adjust", "Adjust", "Ayarla", "Ajustar", "Anpassen", "Ajuster", "Regola", "Ajustar")
add("settings.loading_phase", "Loading phase", "Yükleme fazı", "Fase de carga", "Ladephase", "Phase de charge", "Fase di carico", "Fase de saturação")
add("settings.loading_dose", "Loading dose", "Yükleme dozu", "Dosis de carga", "Ladedosis", "Dose de charge", "Dose di carico", "Dose de saturação")
add("settings.adjust_loading", "Adjust loading dose", "Yükleme dozunu ayarla", "Ajustar dosis de carga", "Ladedosis anpassen", "Ajuster la dose de charge", "Regola la dose di carico", "Ajustar dose de saturação")
add("settings.length %lld",
    P("Length: %lld day", "Length: %lld days"),
    "Süre: %lld gün",
    P("Duración: %lld día", "Duración: %lld días"),
    P("Dauer: %lld Tag", "Dauer: %lld Tage"),
    P("Durée : %lld jour", "Durée : %lld jours"),
    P("Durata: %lld giorno", "Durata: %lld giorni"),
    P("Duração: %lld dia", "Duração: %lld dias"))
add("settings.started_on", "Started on", "Başlangıç", "Inicio", "Begonnen am", "Commencée le", "Iniziata il", "Início")
add("settings.loading_footer %lld",
    P("%lld day of loading left. A dose this size is usually split into several servings across the day.",
      "%lld days of loading left. A dose this size is usually split into several servings across the day."),
    "%lld yükleme günü kaldı. Bu büyüklükte bir doz genelde gün içinde birkaç porsiyona bölünür.",
    P("Queda %lld día de carga. Una dosis así suele dividirse en varias tomas a lo largo del día.",
      "Quedan %lld días de carga. Una dosis así suele dividirse en varias tomas a lo largo del día."),
    P("Noch %lld Ladetag. Eine so große Dosis wird meist auf mehrere Portionen über den Tag verteilt.",
      "Noch %lld Ladetage. Eine so große Dosis wird meist auf mehrere Portionen über den Tag verteilt."),
    P("Il reste %lld jour de charge. Une dose de cette taille se prend généralement en plusieurs prises dans la journée.",
      "Il reste %lld jours de charge. Une dose de cette taille se prend généralement en plusieurs prises dans la journée."),
    P("Manca %lld giorno di carico. Una dose così si divide di solito in più assunzioni durante la giornata.",
      "Mancano %lld giorni di carico. Una dose così si divide di solito in più assunzioni durante la giornata."),
    P("Falta %lld dia de saturação. Uma dose desse tamanho costuma ser dividida em várias porções ao longo do dia.",
      "Faltam %lld dias de saturação. Uma dose desse tamanho costuma ser dividida em várias porções ao longo do dia."))
add("settings.time", "Time", "Saat", "Hora", "Uhrzeit", "Heure", "Orario", "Horário")
add("settings.notifications", "Notifications", "Bildirimler", "Notificaciones", "Mitteilungen", "Notifications", "Notifiche", "Notificações")
add("settings.denied",
    "Notifications are turned off for OneScoop in iOS Settings. Turn them on there to get reminders.",
    "OneScoop için bildirimler iOS Ayarları'nda kapalı. Hatırlatma almak için oradan aç.",
    "Las notificaciones de OneScoop están desactivadas en los Ajustes de iOS. Actívalas ahí para recibir recordatorios.",
    "Mitteilungen für OneScoop sind in den iOS-Einstellungen deaktiviert. Aktiviere sie dort, um Erinnerungen zu erhalten.",
    "Les notifications de OneScoop sont désactivées dans les Réglages d’iOS. Activez-les pour recevoir des rappels.",
    "Le notifiche di OneScoop sono disattivate nelle Impostazioni di iOS. Attivale lì per ricevere promemoria.",
    "As notificações do OneScoop estão desativadas nos Ajustes do iOS. Ative-as lá para receber lembretes.")
add("settings.only_unlogged",
    "You'll only be notified on days you haven't logged a dose yet.",
    "Yalnızca henüz doz kaydetmediğin günlerde bildirim alırsın.",
    "Solo recibirás avisos los días que aún no hayas registrado una dosis.",
    "Du wirst nur an Tagen benachrichtigt, an denen du noch keine Dosis eingetragen hast.",
    "Vous ne serez notifié que les jours où aucune dose n’a encore été notée.",
    "Riceverai notifiche solo nei giorni in cui non hai ancora registrato una dose.",
    "Você só recebe avisos nos dias em que ainda não registrou uma dose.")
add("settings.repeat", "Repeat", "Tekrar", "Repetir", "Wiederholen", "Répéter", "Ripeti", "Repetir")
add("settings.remind_again", "Remind me again", "Tekrar hatırlat", "Recordármelo de nuevo", "Erneut erinnern", "Me le rappeler à nouveau", "Ricordamelo di nuovo", "Lembrar de novo")
add("settings.every", "Every", "Her", "Cada", "Alle", "Toutes les", "Ogni", "A cada")
add("settings.minutes %lld", "%lld min", "%lld dk", "%lld min", "%lld Min.", "%lld min", "%lld min", "%lld min")
add("settings.hours %lld",
    P("%lld hr", "%lld hr"), "%lld sa", "%lld h", "%lld Std.", "%lld h", "%lld h", "%lld h")
add("settings.up_to %lld",
    P("Up to %lld more time", "Up to %lld more times"),
    "En fazla %lld kez daha",
    P("Hasta %lld vez más", "Hasta %lld veces más"),
    P("Bis zu %lld weiteres Mal", "Bis zu %lld weitere Male"),
    P("Jusqu’à %lld fois de plus", "Jusqu’à %lld fois de plus"),
    P("Fino a %lld altra volta", "Fino a %lld altre volte"),
    P("Até %lld vez a mais", "Até %lld vezes a mais"))
add("settings.repeat_footer_on %@ %@",
    "After %1$@, you'll be nudged every %2$@ until you log the dose. Repeats stop at midnight and are all cancelled the moment you tap Yes.",
    "%1$@ sonrasında dozu kaydedene kadar her %2$@ bir hatırlatılırsın. Tekrarlar gece yarısı durur ve Evet'e dokunduğun anda hepsi iptal olur.",
    "Después de las %1$@, te avisaremos cada %2$@ hasta que registres la dosis. Los avisos se detienen a medianoche y se cancelan en cuanto tocas Sí.",
    "Nach %1$@ wirst du alle %2$@ erinnert, bis du die Dosis einträgst. Die Wiederholungen enden um Mitternacht und werden sofort gelöscht, wenn du auf Ja tippst.",
    "Après %1$@, vous serez relancé toutes les %2$@ jusqu’à ce que vous notiez la dose. Les rappels s’arrêtent à minuit et sont tous annulés dès que vous touchez Oui.",
    "Dopo le %1$@, riceverai un promemoria ogni %2$@ finché non registri la dose. Le ripetizioni si fermano a mezzanotte e vengono annullate appena tocchi Sì.",
    "Depois das %1$@, você será lembrado a cada %2$@ até registrar a dose. As repetições param à meia-noite e são canceladas assim que você toca em Sim.")
add("settings.repeat_footer_off",
    "Get another nudge if you still haven't logged your dose after the first reminder.",
    "İlk hatırlatmadan sonra hâlâ dozunu kaydetmediysen bir kez daha hatırlatılırsın.",
    "Recibe otro aviso si después del primer recordatorio aún no has registrado tu dosis.",
    "Erhalte eine weitere Erinnerung, falls du nach der ersten noch nichts eingetragen hast.",
    "Recevez un nouveau rappel si vous n’avez toujours pas noté votre dose après le premier.",
    "Ricevi un altro promemoria se dopo il primo non hai ancora registrato la dose.",
    "Receba outro aviso se, depois do primeiro lembrete, você ainda não registrou a dose.")
add("settings.widget", "Widget", "Widget", "Widget", "Widget", "Widget", "Widget", "Widget")
add("settings.widget_help",
    "Long-press your home screen, tap Edit, then Add Widget and pick OneScoop. You can log the dose straight from the widget.",
    "Ana ekranına uzun bas, Düzenle'ye, ardından Widget Ekle'ye dokun ve OneScoop'u seç. Dozu doğrudan widget'tan kaydedebilirsin.",
    "Mantén pulsada la pantalla de inicio, toca Editar, luego Añadir widget y elige OneScoop. Puedes registrar la dosis directamente desde el widget.",
    "Halte den Home-Bildschirm gedrückt, tippe auf „Bearbeiten“, dann auf „Widget hinzufügen“ und wähle OneScoop. Du kannst die Dosis direkt im Widget eintragen.",
    "Maintenez le doigt sur l’écran d’accueil, touchez Modifier, puis Ajouter un widget et choisissez OneScoop. Vous pouvez noter la dose directement depuis le widget.",
    "Tieni premuto sulla schermata Home, tocca Modifica, poi Aggiungi widget e scegli OneScoop. Puoi registrare la dose direttamente dal widget.",
    "Toque e segure a Tela de Início, toque em Editar, depois em Adicionar widget e escolha o OneScoop. Dá para registrar a dose direto pelo widget.")
add("settings.reset", "Reset all data", "Tüm verileri sıfırla", "Borrar todos los datos", "Alle Daten zurücksetzen", "Réinitialiser toutes les données", "Reimposta tutti i dati", "Apagar todos os dados")
add("settings.local_only",
    "Everything is stored on this device only. Nothing is uploaded anywhere.",
    "Her şey yalnızca bu cihazda saklanır. Hiçbir yere yüklenmez.",
    "Todo se guarda solo en este dispositivo. No se sube nada a ningún sitio.",
    "Alles wird nur auf diesem Gerät gespeichert. Nichts wird irgendwohin hochgeladen.",
    "Tout est stocké uniquement sur cet appareil. Rien n’est envoyé nulle part.",
    "Tutto è salvato solo su questo dispositivo. Non viene caricato nulla.",
    "Tudo fica salvo só neste aparelho. Nada é enviado para lugar nenhum.")
add("settings.reset_title", "Reset all data?", "Tüm veriler sıfırlansın mı?", "¿Borrar todos los datos?", "Alle Daten zurücksetzen?", "Réinitialiser toutes les données ?", "Reimpostare tutti i dati?", "Apagar todos os dados?")
add("settings.delete_all", "Delete everything", "Hepsini sil", "Borrar todo", "Alles löschen", "Tout supprimer", "Elimina tutto", "Apagar tudo")
add("settings.reset_msg",
    "This clears your history and settings, and takes you back to setup.",
    "Geçmişini ve ayarlarını siler, seni kurulum ekranına geri götürür.",
    "Esto borra tu historial y tus ajustes, y te devuelve a la configuración inicial.",
    "Dadurch werden dein Verlauf und deine Einstellungen gelöscht und du kehrst zur Einrichtung zurück.",
    "Cela efface votre historique et vos réglages, et vous ramène à la configuration.",
    "Questo cancella cronologia e impostazioni e ti riporta alla configurazione iniziale.",
    "Isso apaga seu histórico e seus ajustes e volta para a configuração inicial.")

# ── Stok ───────────────────────────────────────────────────
add("supply.empty_title", "Know when you'll run out", "Ne zaman biteceğini bil", "Sabe cuándo se te acabará", "Wisse, wann er leer ist", "Sachez quand vous serez à court", "Sappi quando finirà", "Saiba quando vai acabar")
add("supply.empty_body",
    "Tell OneScoop how big your tub is. Every dose you log is subtracted, so you always know how many days you have left.",
    "OneScoop'a kutunun ne kadar büyük olduğunu söyle. Kaydettiğin her doz düşülür, böylece kaç günün kaldığını hep bilirsin.",
    "Dile a OneScoop de qué tamaño es tu bote. Cada dosis que registras se descuenta, así que siempre sabrás cuántos días te quedan.",
    "Sag OneScoop, wie groß deine Dose ist. Jede eingetragene Dosis wird abgezogen, so weißt du immer, wie viele Tage dir bleiben.",
    "Indiquez à OneScoop la taille de votre pot. Chaque dose notée est déduite : vous savez toujours combien de jours il vous reste.",
    "Di’ a OneScoop quanto è grande il tuo barattolo. Ogni dose registrata viene sottratta, così sai sempre quanti giorni ti restano.",
    "Diga ao OneScoop o tamanho do seu pote. Cada dose registrada é descontada, então você sempre sabe quantos dias restam.")
add("supply.setup", "Set up supply", "Stoku ayarla", "Configurar reserva", "Vorrat einrichten", "Configurer le stock", "Imposta la scorta", "Configurar estoque")
add("supply.g_left", "g left", "g kaldı", "g restantes", "g übrig", "g restants", "g rimasti", "g restantes")
add("supply.of_container %@", "of %@ g container", "%@ g'lık kutudan", "de un envase de %@ g", "von %@ g Dose", "sur un pot de %@ g", "su una confezione da %@ g", "de um pote de %@ g")
add("supply.days_left", "days left", "gün kaldı", "días restantes", "Tage übrig", "jours restants", "giorni rimasti", "dias restantes")
add("supply.runs_out", "runs out", "bitiş", "se acaba", "leer am", "épuisé le", "finisce", "acaba em")
add("supply.per_day", "per day", "günlük", "al día", "pro Tag", "par jour", "al giorno", "por dia")
add("supply.out",
    "You're out. Log a new container when it arrives.",
    "Stokun bitti. Yeni kutu gelince kaydet.",
    "Se te acabó. Registra un envase nuevo cuando llegue.",
    "Dein Vorrat ist leer. Trage eine neue Dose ein, sobald sie da ist.",
    "Vous êtes à court. Enregistrez un nouveau pot à son arrivée.",
    "Sei rimasto senza. Registra una nuova confezione quando arriva.",
    "Acabou. Registre um novo pote quando chegar.")
add("supply.low %lld",
    P("Running low — about %lld day left. Good time to reorder.", "Running low — about %lld days left. Good time to reorder."),
    "Azalıyor — yaklaşık %lld gün kaldı. Sipariş vermenin tam zamanı.",
    P("Queda poco: unos %lld día. Buen momento para volver a pedir.", "Queda poco: unos %lld días. Buen momento para volver a pedir."),
    P("Wird knapp – noch etwa %lld Tag. Zeit nachzubestellen.", "Wird knapp – noch etwa %lld Tage. Zeit nachzubestellen."),
    P("Bientôt épuisé — environ %lld jour restant. C’est le moment de recommander.", "Bientôt épuisé — environ %lld jours restants. C’est le moment de recommander."),
    P("Sta finendo: circa %lld giorno rimasto. È il momento di riordinare.", "Sta finendo: circa %lld giorni rimasti. È il momento di riordinare."),
    P("Está acabando — cerca de %lld dia restante. Boa hora para comprar mais.", "Está acabando — cerca de %lld dias restantes. Boa hora para comprar mais."))
add("supply.new_container", "New container", "Yeni kutu", "Envase nuevo", "Neue Dose", "Nouveau pot", "Nuova confezione", "Novo pote")
add("supply.correct", "Correct the amount", "Miktarı düzelt", "Corregir la cantidad", "Menge korrigieren", "Corriger la quantité", "Correggi la quantità", "Corrigir a quantidade")
add("supply.remaining %@", "%@ g remaining", "%@ g kaldı", "Quedan %@ g", "%@ g übrig", "%@ g restants", "%@ g rimasti", "%@ g restantes")
add("supply.turn_off", "Turn off supply tracking", "Stok takibini kapat", "Desactivar seguimiento de reserva", "Vorratsverfolgung ausschalten", "Désactiver le suivi du stock", "Disattiva il monitoraggio della scorta", "Desativar controle de estoque")
add("supply.sheet_q", "How big is the container?", "Kutu ne kadar büyük?", "¿De qué tamaño es el envase?", "Wie groß ist die Dose?", "Quelle est la taille du pot ?", "Quanto è grande la confezione?", "Qual é o tamanho do pote?")
add("supply.sheet_hint",
    "Each logged dose is subtracted from this. You can correct the remaining amount any time.",
    "Kaydedilen her doz bundan düşülür. Kalan miktarı istediğin zaman düzeltebilirsin.",
    "Cada dosis registrada se resta de aquí. Puedes corregir la cantidad restante cuando quieras.",
    "Jede eingetragene Dosis wird davon abgezogen. Die Restmenge kannst du jederzeit korrigieren.",
    "Chaque dose notée est déduite de ce total. Vous pouvez corriger la quantité restante à tout moment.",
    "Ogni dose registrata viene sottratta da qui. Puoi correggere la quantità rimanente in qualsiasi momento.",
    "Cada dose registrada é descontada daqui. Você pode corrigir a quantidade restante quando quiser.")
add("supply.sheet_start", "Start with a full container", "Dolu kutuyla başla", "Empezar con el envase lleno", "Mit voller Dose starten", "Commencer avec un pot plein", "Inizia con la confezione piena", "Começar com o pote cheio")

# ── Bildirim ───────────────────────────────────────────────
add("notif.first",
    "It's time to take your daily creatine!", "Günlük kreatinini alma vakti!", "¡Es hora de tomar tu creatina diaria!",
    "Zeit für dein tägliches Kreatin!", "C’est l’heure de votre créatine du jour !",
    "È ora della tua creatina quotidiana!", "Hora de tomar sua creatina do dia!")
add("notif.repeat",
    "Still haven't logged today's creatine.", "Bugünkü kreatinini hâlâ kaydetmedin.",
    "Aún no has registrado la creatina de hoy.", "Das heutige Kreatin ist noch nicht eingetragen.",
    "Vous n’avez pas encore noté la créatine du jour.", "Non hai ancora registrato la creatina di oggi.",
    "Você ainda não registrou a creatina de hoje.")
add("notif.log_it", "Log it", "Kaydet", "Registrar", "Eintragen", "Noter", "Registra", "Registrar")

# ── Siri / Kısayollar / App Intents ────────────────────────
add("intent.log.title", "Log today's creatine", "Bugünkü kreatini kaydet", "Registrar la creatina de hoy", "Heutiges Kreatin eintragen", "Noter la créatine du jour", "Registra la creatina di oggi", "Registrar a creatina de hoje")
add("intent.log.desc", "Marks today's creatine dose as taken.", "Bugünkü kreatin dozunu alındı olarak işaretler.", "Marca la dosis de creatina de hoy como tomada.", "Markiert die heutige Kreatindosis als genommen.", "Marque la dose de créatine du jour comme prise.", "Segna la dose di creatina di oggi come presa.", "Marca a dose de creatina de hoje como tomada.")
add("intent.undo.title", "Undo today's creatine", "Bugünkü kaydı geri al", "Deshacer la creatina de hoy", "Heutigen Eintrag rückgängig machen", "Annuler la créatine du jour", "Annulla la creatina di oggi", "Desfazer a creatina de hoje")
add("intent.undo.desc", "Removes today's creatine entry.", "Bugünkü kreatin kaydını siler.", "Elimina el registro de creatina de hoy.", "Entfernt den heutigen Kreatin-Eintrag.", "Supprime l’entrée de créatine du jour.", "Rimuove la voce di creatina di oggi.", "Remove o registro de creatina de hoje.")
add("shortcut.log", "Log creatine", "Kreatin kaydet", "Registrar creatina", "Kreatin eintragen", "Noter la créatine", "Registra creatina", "Registrar creatina")
add("shortcut.undo", "Undo today", "Bugünü geri al", "Deshacer hoy", "Heute rückgängig", "Annuler aujourd’hui", "Annulla oggi", "Desfazer hoje")

# ── Widget ─────────────────────────────────────────────────
add("widget.dose_logged", "Dose logged", "Doz kaydedildi", "Dosis registrada", "Dosis eingetragen", "Dose notée", "Dose registrata", "Dose registrada")
add("widget.grams_today %@", "%@ g today", "Bugün %@ g", "%@ g hoy", "Heute %@ g", "%@ g aujourd’hui", "%@ g oggi", "%@ g hoje")
add("widget.streak %lld",
    P("· %lld day streak", "· %lld day streak"),
    "· %lld günlük seri",
    P("· racha de %lld día", "· racha de %lld días"),
    P("· %lld Tag in Folge", "· %lld Tage in Folge"),
    P("· %lld jour d’affilée", "· %lld jours d’affilée"),
    P("· %lld giorno di fila", "· %lld giorni di fila"),
    P("· %lld dia seguido", "· %lld dias seguidos"))
add("widget.description",
    "Log today's creatine without opening the app.", "Uygulamayı açmadan bugünkü kreatini kaydet.",
    "Registra la creatina de hoy sin abrir la app.", "Trage das heutige Kreatin ein, ohne die App zu öffnen.",
    "Notez la créatine du jour sans ouvrir l’app.", "Registra la creatina di oggi senza aprire l’app.",
    "Registre a creatina de hoje sem abrir o app.")

# ── iCloud ────────────────────────────────────────────────
add("settings.icloud", "iCloud", "iCloud", "iCloud", "iCloud", "iCloud", "iCloud", "iCloud")
add("settings.icloud_toggle",
    "Back up to iCloud", "iCloud'a yedekle", "Copia en iCloud", "In iCloud sichern",
    "Sauvegarder dans iCloud", "Backup su iCloud", "Backup no iCloud")
add("settings.icloud_on",
    "Your history and settings are kept in your own iCloud account, so they come back if you reinstall OneScoop or move to a new iPhone.",
    "Geçmişin ve ayarların kendi iCloud hesabında tutulur; OneScoop'u yeniden yüklediğinde ya da yeni bir iPhone'a geçtiğinde geri gelir.",
    "Tu historial y tus ajustes se guardan en tu propia cuenta de iCloud, así que vuelven si reinstalas OneScoop o cambias de iPhone.",
    "Dein Verlauf und deine Einstellungen liegen in deinem eigenen iCloud-Konto und sind wieder da, wenn du OneScoop neu installierst oder ein neues iPhone nutzt.",
    "Votre historique et vos réglages sont conservés dans votre propre compte iCloud : ils reviennent si vous réinstallez OneScoop ou changez d’iPhone.",
    "Cronologia e impostazioni restano nel tuo account iCloud, così tornano se reinstalli OneScoop o passi a un nuovo iPhone.",
    "Seu histórico e seus ajustes ficam na sua própria conta do iCloud e voltam se você reinstalar o OneScoop ou trocar de iPhone.")
add("settings.icloud_off",
    "Your data stays on this iPhone only. Deleting the app deletes it too.",
    "Verilerin yalnızca bu iPhone'da kalır. Uygulamayı silersen onlar da silinir.",
    "Tus datos se quedan solo en este iPhone. Si borras la app, también se borran.",
    "Deine Daten bleiben nur auf diesem iPhone. Wenn du die App löschst, sind sie auch weg.",
    "Vos données restent uniquement sur cet iPhone. Supprimer l’app les supprime aussi.",
    "I tuoi dati restano solo su questo iPhone. Se elimini l’app, vengono eliminati anche loro.",
    "Seus dados ficam só neste iPhone. Se você apagar o app, eles também são apagados.")
add("settings.reset_icloud",
    "This also removes your OneScoop data from iCloud and your other devices.",
    "OneScoop verilerini iCloud'dan ve diğer cihazlarından da siler.",
    "También borra tus datos de OneScoop de iCloud y de tus otros dispositivos.",
    "Entfernt deine OneScoop-Daten auch aus iCloud und von deinen anderen Geräten.",
    "Supprime aussi vos données OneScoop d’iCloud et de vos autres appareils.",
    "Rimuove i dati di OneScoop anche da iCloud e dagli altri dispositivi.",
    "Também apaga seus dados do OneScoop do iCloud e dos seus outros aparelhos.")

# ── Geri yükleme ─────────────────────────────────────────
add("restore.checking",
    "Looking for your history in iCloud…", "Geçmişin iCloud'da aranıyor…",
    "Buscando tu historial en iCloud…", "Dein Verlauf wird in iCloud gesucht …",
    "Recherche de votre historique dans iCloud…", "Ricerca della cronologia in iCloud…",
    "Procurando seu histórico no iCloud…")

# ── Apple Watch ────────────────────────────────────────────
add("watch.setup_first",
    "Set up OneScoop on your iPhone first.", "Önce OneScoop'u iPhone'unda kur.",
    "Primero configura OneScoop en tu iPhone.", "Richte OneScoop zuerst auf deinem iPhone ein.",
    "Configurez d’abord OneScoop sur votre iPhone.", "Configura prima OneScoop sul tuo iPhone.",
    "Configure o OneScoop no iPhone primeiro.")

# ── Denetim Merkezi / Eylem düğmesi ───────────────────────
add("control.description",
    "Log today's creatine from Control Center or the Action button.",
    "Bugünkü kreatini Denetim Merkezi'nden ya da Eylem düğmesinden kaydet.",
    "Registra la creatina de hoy desde el Centro de control o el botón de acción.",
    "Trage dein heutiges Kreatin im Kontrollzentrum oder mit der Aktionstaste ein.",
    "Notez la créatine du jour depuis le centre de contrôle ou le bouton Action.",
    "Registra la creatina di oggi dal Centro di Controllo o dal tasto Azione.",
    "Registre a creatina de hoje pela Central de Controle ou pelo botão de Ação.")

# ── Saat kadranı (complication) ────────────────────────────
add("complication.not_yet",
    "Not logged yet", "Henüz kaydedilmedi", "Aún sin registrar", "Noch nicht eingetragen",
    "Pas encore noté", "Non ancora registrata", "Ainda não registrado")
add("complication.description",
    "See at a glance whether you've taken today's creatine.",
    "Bugünkü kreatini alıp almadığını tek bakışta gör.",
    "Mira de un vistazo si ya tomaste la creatina de hoy.",
    "Sieh auf einen Blick, ob du dein Kreatin heute schon genommen hast.",
    "Voyez d’un coup d’œil si vous avez pris votre créatine aujourd’hui.",
    "Vedi a colpo d’occhio se hai già preso la creatina oggi.",
    "Veja num relance se você já tomou a creatina de hoje.")

# ── 2.0: Su ───────────────────────────────────────────────
add("common.done", "Done", "Bitti", "Listo", "Fertig", "OK", "Fine", "OK")
add("water.title", "Water", "Su", "Agua", "Wasser", "Eau", "Acqua", "Água")
add("water.goal_reached",
    "Goal reached", "Hedefe ulaştın", "Objetivo cumplido", "Ziel erreicht",
    "Objectif atteint", "Obiettivo raggiunto", "Meta atingida")
add("water.pace_on",
    "Right on pace", "Tempondasın", "Vas a buen ritmo", "Du liegst im Plan",
    "Vous êtes dans le rythme", "Sei in linea", "No ritmo certo")
add("water.pace_behind %@",
    "%@ ml behind your pace", "Temponun %@ ml gerisindesin", "%@ ml por detrás de tu ritmo",
    "%@ ml hinter deinem Plan", "%@ ml de retard sur votre rythme",
    "%@ ml indietro rispetto al ritmo", "%@ ml atrás do seu ritmo")
add("water.cup.glass", "Glass", "Bardak", "Vaso", "Glas", "Verre", "Bicchiere", "Copo")
add("water.cup.shaker", "Shaker", "Shaker", "Shaker", "Shaker", "Shaker", "Shaker", "Coqueteleira")
add("water.cup.bottle", "Bottle", "Şişe", "Botella", "Flasche", "Gourde", "Borraccia", "Garrafa")
add("water.today_entries",
    "Today's water", "Bugünkü su", "Agua de hoy", "Heutiges Wasser",
    "Eau du jour", "Acqua di oggi", "Água de hoje")
add("water.no_entries",
    "Nothing logged yet today.", "Bugün henüz su kaydı yok.", "Aún no hay nada registrado hoy.",
    "Heute noch nichts eingetragen.", "Rien de noté pour l’instant aujourd’hui.",
    "Oggi non hai ancora registrato nulla.", "Nada registrado hoje ainda.")
add("water.delete", "Delete", "Sil", "Eliminar", "Löschen", "Supprimer", "Elimina", "Apagar")

add("whatsnew.water_title",
    "New: Water", "Yeni: Su", "Nuevo: Agua", "Neu: Wasser", "Nouveau : l’eau",
    "Novità: acqua", "Novo: água")
add("whatsnew.water_body",
    "Track water the same way you track creatine: one tap, right next to your daily dose.",
    "Suyu da kreatin gibi takip et: tek dokunuş, günlük dozunun hemen yanında.",
    "Registra el agua igual que la creatina: un toque, justo al lado de tu dosis diaria.",
    "Erfasse Wasser genau wie Kreatin: ein Tipp, direkt neben deiner Tagesdosis.",
    "Suivez l’eau comme la créatine : un geste, juste à côté de votre dose du jour.",
    "Registra l’acqua come la creatina: un tocco, proprio accanto alla dose giornaliera.",
    "Registre a água do mesmo jeito que a creatina: um toque, ao lado da sua dose diária.")
add("whatsnew.water_try",
    "Turn on water tracking", "Su takibini aç", "Activar el registro de agua",
    "Wasser-Tracking einschalten", "Activer le suivi de l’eau",
    "Attiva il monitoraggio dell’acqua", "Ativar o registro de água")

add("plus.not_now", "Not now", "Şimdi değil", "Ahora no", "Nicht jetzt", "Plus tard", "Non ora", "Agora não")
add("plus.headline",
    "Pay once, keep it forever.", "Bir kez öde, hep senin.", "Paga una vez y es tuyo para siempre.",
    "Einmal zahlen, für immer behalten.", "Payez une fois, gardez-le pour toujours.",
    "Paghi una volta, è tuo per sempre.", "Pague uma vez e é seu para sempre.")
add("plus.bullet_anywhere",
    "Add water with one tap from widgets, the Lock Screen, Control Center, the Action button and Siri",
    "Widget'tan, kilit ekranından, Denetim Merkezi'nden, Eylem düğmesinden ve Siri'den tek dokunuşla su ekle",
    "Añade agua con un toque desde widgets, la pantalla bloqueada, el Centro de control, el botón de acción y Siri",
    "Wasser mit einem Tipp über Widgets, Sperrbildschirm, Kontrollzentrum, Aktionstaste und Siri hinzufügen",
    "Ajoutez de l’eau d’un geste depuis les widgets, l’écran verrouillé, le centre de contrôle, le bouton Action et Siri",
    "Aggiungi acqua con un tocco da widget, schermata di blocco, Centro di Controllo, tasto Azione e Siri",
    "Adicione água com um toque pelos widgets, Tela Bloqueada, Central de Controle, botão de Ação e Siri")
add("plus.bullet_health",
    "Apple Health sync: your water is saved there, and water from other apps counts here",
    "Apple Sağlık eşitlemesi: suyun oraya kaydedilir, diğer uygulamalardaki su da burada sayılır",
    "Sincronización con Salud: tu agua se guarda allí y el agua de otras apps cuenta aquí",
    "Apple-Health-Abgleich: dein Wasser wird dort gespeichert, Wasser aus anderen Apps zählt hier",
    "Synchronisation avec Santé : votre eau y est enregistrée et l’eau des autres apps compte ici",
    "Sincronizzazione con Salute: la tua acqua viene salvata lì e quella di altre app conta qui",
    "Sincronização com o Saúde: sua água é salva lá e a água de outros apps conta aqui")
add("plus.bullet_reminders",
    "Smart reminders that learn when you usually drink and only nudge you when you fall behind",
    "Ne zaman su içtiğini öğrenen, sadece geride kaldığında hatırlatan akıllı hatırlatmalar",
    "Recordatorios inteligentes que aprenden cuándo sueles beber y solo avisan si te quedas atrás",
    "Smarte Erinnerungen, die lernen, wann du trinkst, und sich nur melden, wenn du zurückliegst",
    "Des rappels intelligents qui apprennent quand vous buvez et ne se manifestent que si vous êtes en retard",
    "Promemoria intelligenti che imparano quando bevi e ti avvisano solo se resti indietro",
    "Lembretes inteligentes que aprendem quando você bebe e só avisam quando você fica para trás")
add("plus.bullet_cups",
    "Three cups — glass, shaker and bottle — each set to its real size",
    "Üç kap — bardak, shaker ve şişe — her biri kendi gerçek boyutunda",
    "Tres recipientes — vaso, shaker y botella — cada uno con su tamaño real",
    "Drei Gefäße — Glas, Shaker und Flasche — jedes in seiner echten Größe",
    "Trois contenants — verre, shaker et gourde — chacun à sa vraie taille",
    "Tre contenitori — bicchiere, shaker e borraccia — ognuno della sua vera capienza",
    "Três recipientes — copo, coqueteleira e garrafa — cada um no tamanho real")
add("plus.no_subscription",
    "One-time purchase · no subscription", "Tek seferlik · abonelik yok",
    "Pago único · sin suscripción", "Einmalkauf · kein Abo", "Achat unique · sans abonnement",
    "Acquisto unico · nessun abbonamento", "Compra única · sem assinatura")
add("plus.buy", "Unlock OneScoop+", "OneScoop+'ı aç", "Desbloquear OneScoop+", "OneScoop+ freischalten",
    "Débloquer OneScoop+", "Sblocca OneScoop+", "Desbloquear OneScoop+")
add("plus.unavailable",
    "Purchases aren't available yet in this test build.",
    "Bu test sürümünde satın alma henüz hazır değil.",
    "Las compras aún no están disponibles en esta versión de prueba.",
    "Käufe sind in diesem Test-Build noch nicht verfügbar.",
    "Les achats ne sont pas encore disponibles dans cette version de test.",
    "Gli acquisti non sono ancora disponibili in questa build di prova.",
    "As compras ainda não estão disponíveis nesta versão de teste.")
add("plus.restore", "Restore purchases", "Satın alımları geri yükle", "Restaurar compras",
    "Käufe wiederherstellen", "Restaurer les achats", "Ripristina acquisti", "Restaurar compras")
add("plus.family",
    "Shared with your family through Family Sharing.",
    "Aile Paylaşımı ile ailenle de paylaşılır.",
    "Se comparte con tu familia mediante En familia.",
    "Wird per Familienfreigabe mit deiner Familie geteilt.",
    "Partagé avec votre famille via le partage familial.",
    "Condiviso con la famiglia tramite In famiglia.",
    "Compartilhado com sua família pelo Compartilhamento Familiar.")
add("plus.unlocked",
    "OneScoop+ is unlocked. Thank you!", "OneScoop+ açık. Teşekkürler!",
    "OneScoop+ está desbloqueado. ¡Gracias!", "OneScoop+ ist freigeschaltet. Danke!",
    "OneScoop+ est débloqué. Merci !", "OneScoop+ è sbloccato. Grazie!",
    "OneScoop+ está desbloqueado. Obrigado!")

add("settings.water", "Water", "Su", "Agua", "Wasser", "Eau", "Acqua", "Água")
add("settings.water_toggle", "Track water", "Su takibi", "Registrar agua", "Wasser erfassen",
    "Suivre l’eau", "Monitora l’acqua", "Registrar água")
add("settings.water_goal", "Daily goal", "Günlük hedef", "Objetivo diario", "Tagesziel",
    "Objectif quotidien", "Obiettivo giornaliero", "Meta diária")
add("settings.water_default", "Default cup", "Varsayılan kap", "Vaso predeterminado",
    "Standardgefäß", "Contenant par défaut", "Contenitore predefinito", "Copo padrão")
add("settings.water_footer",
    "The goal is an estimate, not medical advice.",
    "Hedef bir tahmindir, tıbbi tavsiye değildir.",
    "El objetivo es una estimación, no un consejo médico.",
    "Das Ziel ist eine Schätzung, kein medizinischer Rat.",
    "L’objectif est une estimation, pas un avis médical.",
    "L’obiettivo è una stima, non un consiglio medico.",
    "A meta é uma estimativa, não uma orientação médica.")
add("settings.water_cups", "Your cups", "Kapların", "Tus vasos", "Deine Gefäße",
    "Vos contenants", "I tuoi contenitori", "Seus copos")
add("settings.water_cups_footer",
    "Set each one to its real size. They appear as buttons on the Today tab.",
    "Her birini gerçek hacmine ayarla. Bugün sekmesinde buton olarak görünürler.",
    "Ajusta cada uno a su tamaño real. Aparecen como botones en la pestaña Hoy.",
    "Stell jedes auf seine echte Größe ein. Sie erscheinen als Tasten im Tab „Heute“.",
    "Réglez chacun sur sa taille réelle. Ils apparaissent comme boutons dans l’onglet Aujourd’hui.",
    "Imposta ognuno sulla sua capienza reale. Compaiono come pulsanti nella scheda Oggi.",
    "Ajuste cada um ao tamanho real. Eles aparecem como botões na aba Hoje.")

add("widget.water_name", "Water", "Su", "Agua", "Wasser", "Eau", "Acqua", "Água")
add("widget.water_desc",
    "Add water with one tap and see how far you are from your goal.",
    "Tek dokunuşla su ekle, hedefine ne kadar kaldığını gör.",
    "Añade agua con un toque y mira cuánto te falta para tu objetivo.",
    "Füge Wasser mit einem Tipp hinzu und sieh, wie weit du von deinem Ziel entfernt bist.",
    "Ajoutez de l’eau d’un geste et voyez où vous en êtes de votre objectif.",
    "Aggiungi acqua con un tocco e guarda quanto manca al tuo obiettivo.",
    "Adicione água com um toque e veja quanto falta para a sua meta.")
add("widget.water_off",
    "Turn on water tracking in OneScoop.", "Su takibini OneScoop'ta aç.",
    "Activa el registro de agua en OneScoop.", "Schalte Wasser-Tracking in OneScoop ein.",
    "Activez le suivi de l’eau dans OneScoop.", "Attiva il monitoraggio dell’acqua in OneScoop.",
    "Ative o registro de água no OneScoop.")
add("widget.water_plus",
    "Log from here with OneScoop+.", "Buradan eklemek için OneScoop+.",
    "Registra desde aquí con OneScoop+.", "Mit OneScoop+ direkt hier eintragen.",
    "Notez d’ici avec OneScoop+.", "Registra da qui con OneScoop+.",
    "Registre daqui com o OneScoop+.")
add("control.water_desc",
    "Add your default cup of water.", "Varsayılan kabın kadar su ekle.",
    "Añade tu vaso de agua predeterminado.", "Füge dein Standardgefäß Wasser hinzu.",
    "Ajoutez votre contenant d’eau par défaut.", "Aggiungi il tuo contenitore d’acqua predefinito.",
    "Adicione seu copo de água padrão.")
add("intent.water.title", "Add water", "Su ekle", "Añadir agua", "Wasser hinzufügen",
    "Ajouter de l’eau", "Aggiungi acqua", "Adicionar água")
add("intent.water.desc",
    "Adds water to today's total in OneScoop.", "OneScoop'ta bugünkü toplama su ekler.",
    "Añade agua al total de hoy en OneScoop.", "Fügt Wasser zur heutigen Menge in OneScoop hinzu.",
    "Ajoute de l’eau au total du jour dans OneScoop.", "Aggiunge acqua al totale di oggi in OneScoop.",
    "Adiciona água ao total de hoje no OneScoop.")
add("intent.water_undo.title", "Undo last water", "Son suyu geri al", "Deshacer el último agua",
    "Letztes Wasser widerrufen", "Annuler la dernière eau", "Annulla l’ultima acqua", "Desfazer a última água")
add("intent.water.amount", "Amount (ml)", "Miktar (ml)", "Cantidad (ml)", "Menge (ml)",
    "Quantité (ml)", "Quantità (ml)", "Quantidade (ml)")

# ── 2.0: Su hatırlatmaları ────────────────────────────────
add("settings.water_reminders", "Water reminders", "Su hatırlatmaları", "Recordatorios de agua",
    "Wasser-Erinnerungen", "Rappels d’eau", "Promemoria acqua", "Lembretes de água")
add("settings.water_remind_off", "Off", "Kapalı", "Desactivados", "Aus", "Désactivés", "Disattivati", "Desativados")
add("settings.water_remind_simple", "Simple", "Basit", "Simples", "Einfach", "Simples", "Semplici", "Simples")
add("settings.water_remind_smart", "Smart (OneScoop+)", "Akıllı (OneScoop+)", "Inteligentes (OneScoop+)",
    "Smart (OneScoop+)", "Intelligents (OneScoop+)", "Intelligenti (OneScoop+)", "Inteligentes (OneScoop+)")
add("settings.water_every %lld",
    P("Every %lld hour", "Every %lld hours"),
    "%lld saatte bir",
    P("Cada %lld hora", "Cada %lld horas"),
    P("Alle %lld Stunde", "Alle %lld Stunden"),
    P("Toutes les %lld heure", "Toutes les %lld heures"),
    P("Ogni %lld ora", "Ogni %lld ore"),
    P("A cada %lld hora", "A cada %lld horas"))
add("settings.water_day_start", "Day starts", "Gün başlangıcı", "El día empieza", "Tagesbeginn",
    "Début de journée", "Inizio giornata", "Início do dia")
add("settings.water_day_end", "Day ends", "Gün bitişi", "El día termina", "Tagesende",
    "Fin de journée", "Fine giornata", "Fim do dia")
add("settings.water_remind_off_footer",
    "No water reminders.", "Su için hatırlatma gelmez.", "No recibirás recordatorios de agua.",
    "Keine Wasser-Erinnerungen.", "Aucun rappel d’eau.", "Nessun promemoria per l’acqua.",
    "Nenhum lembrete de água.")
add("settings.water_remind_simple_footer",
    "A reminder at a fixed interval during your day. They stop once you reach your goal.",
    "Gün içinde sabit aralıklarla hatırlatır. Hedefe ulaşınca susar.",
    "Un recordatorio a intervalos fijos durante tu día. Se detienen al alcanzar tu objetivo.",
    "Eine Erinnerung in festen Abständen über den Tag. Sie hören auf, sobald du dein Ziel erreichst.",
    "Un rappel à intervalle fixe pendant la journée. Ils s’arrêtent une fois l’objectif atteint.",
    "Un promemoria a intervalli fissi durante la giornata. Si fermano quando raggiungi l’obiettivo.",
    "Um lembrete em intervalos fixos durante o dia. Eles param quando você atinge a meta.")
add("settings.water_remind_smart_ready",
    "OneScoop has learned when you usually drink. You only get a reminder when you're clearly behind your own routine.",
    "OneScoop genelde ne zaman su içtiğini öğrendi. Sadece kendi düzeninin belirgin gerisinde kaldığında hatırlatır.",
    "OneScoop ya sabe cuándo sueles beber. Solo te avisa cuando vas claramente por detrás de tu propia rutina.",
    "OneScoop weiß jetzt, wann du normalerweise trinkst. Du wirst nur erinnert, wenn du deutlich hinter deiner eigenen Routine liegst.",
    "OneScoop a appris quand vous buvez d’habitude. Vous n’êtes rappelé que si vous êtes nettement en retard sur votre propre rythme.",
    "OneScoop ha imparato quando bevi di solito. Ti avvisa solo quando sei chiaramente indietro rispetto alla tua routine.",
    "O OneScoop já aprendeu quando você costuma beber. Você só recebe um lembrete quando está claramente atrás da sua própria rotina.")
add("settings.water_remind_smart_learning %lld %lld",
    "Learning your routine: %1$lld of %2$lld days. Until then, reminders follow your daily goal.",
    "Düzenin öğreniliyor: %1$lld/%2$lld gün. O zamana kadar günlük hedefine göre hatırlatır.",
    "Aprendiendo tu rutina: %1$lld de %2$lld días. Mientras tanto, los recordatorios siguen tu objetivo diario.",
    "Deine Routine wird gelernt: %1$lld von %2$lld Tagen. Bis dahin richten sich die Erinnerungen nach deinem Tagesziel.",
    "Apprentissage de votre rythme : %1$lld jour(s) sur %2$lld. D’ici là, les rappels suivent votre objectif quotidien.",
    "Sto imparando la tua routine: %1$lld di %2$lld giorni. Fino ad allora i promemoria seguono l’obiettivo giornaliero.",
    "Aprendendo sua rotina: %1$lld de %2$lld dias. Até lá, os lembretes seguem sua meta diária.")
add("notif.water_simple",
    "Time for some water.", "Bir bardak su vakti.", "Hora de beber agua.", "Zeit für etwas Wasser.",
    "C’est l’heure de boire de l’eau.", "È ora di bere un po’ d’acqua.", "Hora de beber água.")
add("notif.water_smart %@ %@",
    "By now you've usually had %1$@ L. Today you're at %2$@ L.",
    "Genelde bu saate kadar %1$@ L içmiş oluyorsun. Bugün %2$@ L'desin.",
    "A esta hora sueles llevar %1$@ L. Hoy vas por %2$@ L.",
    "Um diese Zeit hast du meist schon %1$@ L getrunken. Heute sind es %2$@ L.",
    "À cette heure, vous en êtes d’habitude à %1$@ L. Aujourd’hui : %2$@ L.",
    "A quest’ora di solito sei a %1$@ L. Oggi sei a %2$@ L.",
    "Até esta hora você costuma ter bebido %1$@ L. Hoje você está em %2$@ L.")
add("notif.water_pace %@",
    "You're %@ ml behind today's goal.", "Bugünkü hedefinin %@ ml gerisindesin.",
    "Vas %@ ml por detrás del objetivo de hoy.", "Du liegst %@ ml hinter deinem heutigen Ziel.",
    "Vous avez %@ ml de retard sur l’objectif du jour.", "Sei %@ ml indietro rispetto all’obiettivo di oggi.",
    "Você está %@ ml atrás da meta de hoje.")

# ── 2.0: Takvim (su) ve Apple Sağlık ──────────────────────
add("history.creatine", "Creatine", "Kreatin", "Creatina", "Kreatin", "Créatine", "Creatina", "Creatina")
add("history.water_goal_days", "Days at goal", "Hedefe ulaşılan gün", "Días con objetivo", "Tage am Ziel",
    "Jours à l’objectif", "Giorni a obiettivo", "Dias na meta")
add("history.water_average", "Daily average", "Günlük ortalama", "Media diaria", "Tagesschnitt",
    "Moyenne par jour", "Media giornaliera", "Média diária")
add("history.water_hint",
    "Tap a day to see its water.", "O günün sularını görmek için bir güne dokun.",
    "Toca un día para ver su agua.", "Tippe auf einen Tag, um sein Wasser zu sehen.",
    "Touchez un jour pour voir son eau.", "Tocca un giorno per vederne l’acqua.",
    "Toque em um dia para ver a água dele.")
add("settings.water_health", "Apple Health", "Apple Sağlık", "Salud de Apple", "Apple Health",
    "Santé d’Apple", "Salute di Apple", "Saúde da Apple")
add("settings.water_health_footer",
    "Water you log here is saved to Apple Health, and water from other apps in Health shows up in OneScoop.",
    "Burada girdiğin su Apple Sağlık'a da kaydedilir; Sağlık'taki diğer uygulamaların suyu da OneScoop'ta görünür.",
    "El agua que registras aquí se guarda en Salud, y el agua de otras apps en Salud aparece en OneScoop.",
    "Wasser, das du hier einträgst, wird in Apple Health gespeichert, und Wasser aus anderen Apps in Health erscheint in OneScoop.",
    "L’eau notée ici est enregistrée dans Santé, et l’eau des autres apps dans Santé apparaît dans OneScoop.",
    "L’acqua che registri qui viene salvata in Salute, e l’acqua di altre app in Salute compare in OneScoop.",
    "A água registrada aqui é salva no Saúde, e a água de outros apps no Saúde aparece no OneScoop.")

# ── 2.0: TestFlight test satın alması ─────────────────────
add("plus.test_title", "Test purchase", "Test satın alması", "Compra de prueba", "Testkauf",
    "Achat de test", "Acquisto di prova", "Compra de teste")
add("plus.test_message",
    "This is a TestFlight build. No payment is made, and you can cancel it anytime in Settings.",
    "Bu bir TestFlight sürümü. Ödeme alınmaz; istediğin zaman Ayarlar'dan iptal edebilirsin.",
    "Esta es una versión de TestFlight. No se cobra nada y puedes cancelarla cuando quieras en Ajustes.",
    "Dies ist ein TestFlight-Build. Es wird nichts bezahlt, und du kannst es jederzeit in den Einstellungen zurücknehmen.",
    "Ceci est une version TestFlight. Aucun paiement n’est effectué et vous pouvez l’annuler à tout moment dans Réglages.",
    "Questa è una build TestFlight. Non paghi nulla e puoi annullarlo quando vuoi in Impostazioni.",
    "Esta é uma versão do TestFlight. Nada é cobrado e você pode cancelar quando quiser em Ajustes.")
add("plus.test_buy", "Buy (test)", "Satın al (test)", "Comprar (prueba)", "Kaufen (Test)",
    "Acheter (test)", "Acquista (prova)", "Comprar (teste)")
add("plus.test_note",
    "TestFlight · test purchase, no payment", "TestFlight · test satın alması, ödeme yok",
    "TestFlight · compra de prueba, sin pago", "TestFlight · Testkauf, keine Zahlung",
    "TestFlight · achat de test, sans paiement", "TestFlight · acquisto di prova, nessun pagamento",
    "TestFlight · compra de teste, sem pagamento")
add("settings.test", "Test", "Test", "Prueba", "Test", "Test", "Prova", "Teste")
add("settings.test_plus_on", "Active (test)", "Açık (test)", "Activo (prueba)", "Aktiv (Test)",
    "Actif (test)", "Attivo (prova)", "Ativo (teste)")
add("settings.test_plus_off", "Not purchased", "Satın alınmadı", "No comprado", "Nicht gekauft",
    "Non acheté", "Non acquistato", "Não comprado")
add("settings.test_cancel", "Cancel test purchase", "Test satın almasını iptal et", "Cancelar compra de prueba",
    "Testkauf zurücknehmen", "Annuler l’achat de test", "Annulla acquisto di prova", "Cancelar compra de teste")
add("settings.test_open_paywall", "Open OneScoop+ screen", "OneScoop+ ekranını aç", "Abrir pantalla de OneScoop+",
    "OneScoop+-Bildschirm öffnen", "Ouvrir l’écran OneScoop+", "Apri la schermata OneScoop+", "Abrir tela do OneScoop+")
add("settings.test_footer",
    "Only visible in TestFlight builds. Lets you try OneScoop+ with and without a purchase.",
    "Sadece TestFlight sürümlerinde görünür. OneScoop+'ı satın alınmış ve alınmamış haliyle denemen için.",
    "Solo visible en versiones de TestFlight. Para probar OneScoop+ con y sin compra.",
    "Nur in TestFlight-Builds sichtbar. Zum Testen von OneScoop+ mit und ohne Kauf.",
    "Visible uniquement dans les versions TestFlight. Pour essayer OneScoop+ avec et sans achat.",
    "Visibile solo nelle build TestFlight. Per provare OneScoop+ con e senza acquisto.",
    "Visível só em versões do TestFlight. Para testar o OneScoop+ com e sem compra.")

# App Intents / AppShortcut metinleri koddan doğrudan literal ile okunuyor,
# erişimci üretmeye gerek yok.
NO_ACCESSOR = {"intent.log.title", "intent.log.desc", "intent.undo.title",
               "intent.undo.desc", "shortcut.undo",
               "intent.water.title", "intent.water.desc", "intent.water.amount",
               "intent.water_undo.title"}

# ═══════════════════════════════════════════════════════════
# Doğrulama
# ═══════════════════════════════════════════════════════════
SPEC = re.compile(r"%(\d+\$)?(lld|@)")

def specs_of_key(key):
    return [m.group(2) for m in SPEC.finditer(key)]

def check(key, val, lang):
    texts = list(val.values()) if isinstance(val, dict) else [val]
    want = sorted(specs_of_key(key))
    for t in texts:
        got = sorted(m.group(2) for m in SPEC.finditer(t))
        if got != want:
            raise SystemExit(f"FORMAT MISMATCH [{lang}] {key!r}: key={want} value={got} :: {t}")
        if "%" in t.replace("%%", "") and not SPEC.search(t) and want:
            raise SystemExit(f"STRAY % [{lang}] {key}")

for k, row in T.items():
    for lang in LANGS:
        if lang not in row or row[lang] in (None, ""):
            raise SystemExit(f"MISSING [{lang}] {k}")
        check(k, row[lang], lang)

# ═══════════════════════════════════════════════════════════
# Localizable.xcstrings
# ═══════════════════════════════════════════════════════════
def unit(v):
    return {"stringUnit": {"state": "translated", "value": v}}

strings = {}
for k in sorted(T):
    locs = {}
    for lang in LANGS:
        v = T[k][lang]
        if isinstance(v, dict):
            locs[lang] = {"variations": {"plural": {cat: unit(txt) for cat, txt in v.items()}}}
        else:
            locs[lang] = unit(v)
    strings[k] = {"extractionState": "manual", "localizations": locs}

catalog = {"sourceLanguage": "en", "strings": strings, "version": "1.0"}
with open(os.path.join(ROOT, "Localizable.xcstrings"), "w", encoding="utf-8") as f:
    json.dump(catalog, f, ensure_ascii=False, indent=2, sort_keys=True)

# ═══════════════════════════════════════════════════════════
# L10n.swift
# ═══════════════════════════════════════════════════════════
def swift_name(key):
    base = key.split(" ")[0]
    parts = re.split(r"[._]", base)
    return parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])

lines = [
    "// ⚠️ Bu dosya otomatik üretildi (l10n_build.py). Elle düzenleme.",
    "// Yeni metin eklerken tabloya ekle ve betiği yeniden çalıştır.",
    "import Foundation",
    "",
    "enum L {",
]
names = {}
for k in sorted(T):
    if k in NO_ACCESSOR:
        continue
    name = swift_name(k)
    if name in names:
        raise SystemExit(f"NAME CLASH {name}: {k} vs {names[name]}")
    names[name] = k
    base = k.split(" ")[0]
    types = specs_of_key(k)
    if not types:
        lines.append(f'    static var {name}: String {{ String(localized: "{base}") }}')
    else:
        params = ", ".join(f"_ a{i}: {'Int' if t == 'lld' else 'String'}" for i, t in enumerate(types))
        interp = " ".join(f"\\(a{i})" for i in range(len(types)))
        lines.append(f'    static func {name}({params}) -> String {{ String(localized: "{base} {interp}") }}')
lines.append("}")
lines.append("")
with open(os.path.join(ROOT, "L10n.swift"), "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

# ═══════════════════════════════════════════════════════════
# InfoPlist.xcstrings — iOS izin pencerelerindeki metinler
# ═══════════════════════════════════════════════════════════
PLIST = {
    "NSHealthShareUsageDescription": [
        "OneScoop reads water from Apple Health so water you log in other apps counts toward your daily goal.",
        "OneScoop, diğer uygulamalarda girdiğin su da günlük hedefine sayılsın diye Apple Sağlık'tan su verisini okur.",
        "OneScoop lee el agua de Salud para que el agua que registras en otras apps cuente para tu objetivo diario.",
        "OneScoop liest Wasser aus Apple Health, damit Wasser aus anderen Apps zu deinem Tagesziel zählt.",
        "OneScoop lit l’eau dans Santé pour que l’eau notée dans d’autres apps compte dans votre objectif quotidien.",
        "OneScoop legge l’acqua da Salute così l’acqua registrata in altre app conta per il tuo obiettivo giornaliero.",
        "O OneScoop lê a água do Saúde para que a água registrada em outros apps conte para sua meta diária.",
    ],
    "NSHealthUpdateUsageDescription": [
        "OneScoop saves the water you log to Apple Health.",
        "OneScoop, girdiğin suyu Apple Sağlık'a kaydeder.",
        "OneScoop guarda en Salud el agua que registras.",
        "OneScoop speichert das Wasser, das du einträgst, in Apple Health.",
        "OneScoop enregistre dans Santé l’eau que vous notez.",
        "OneScoop salva in Salute l’acqua che registri.",
        "O OneScoop salva no Saúde a água que você registra.",
    ],
}
plist_strings = {k: {"extractionState": "manual",
                     "localizations": {lang: unit(v) for lang, v in zip(LANGS, vals)}}
                 for k, vals in PLIST.items()}
with open(os.path.join(ROOT, "InfoPlist.xcstrings"), "w", encoding="utf-8") as f:
    json.dump({"sourceLanguage": "en", "strings": plist_strings, "version": "1.0"},
              f, ensure_ascii=False, indent=2, sort_keys=True)

print(f"{len(T)} anahtar × {len(LANGS)} dil — doğrulama geçti")
for n in sorted(names):
    print(" ", n)
