# 2.1 metinleri: rozetler, paylaşım kartı, raporlar, hesaplayıcı, porsiyonlar,
# antrenman sonrası hatırlatma, kutu bitiyor bildirimi.
# l10n_build.py bu dosyayı exec ile çalıştırıyor; add() ve P() oradan geliyor.

# ── Rozet adları ───────────────────────────────────────────
add("badge.c7", "First Week", "İlk Hafta", "Primera semana", "Erste Woche", "Première semaine", "Prima settimana", "Primeira semana")
add("badge.c30", "Habit", "Alışkanlık", "Hábito", "Gewohnheit", "Habitude", "Abitudine", "Hábito")
add("badge.c100", "Hundred", "Yüzlük", "Centenario", "Hunderter", "Centurion", "Centenario", "Centena")
add("badge.c365", "One Year", "Bir Yıl", "Un año", "Ein Jahr", "Un an", "Un anno", "Um ano")
add("badge.w7", "Droplet", "Damla", "Gota", "Tropfen", "Goutte", "Goccia", "Gota")
add("badge.w30", "Stream", "Akıntı", "Corriente", "Strömung", "Courant", "Corrente", "Correnteza")
add("badge.w100", "River", "Nehir", "Río", "Fluss", "Rivière", "Fiume", "Rio")
add("badge.w365", "Ocean", "Okyanus", "Océano", "Ozean", "Océan", "Oceano", "Oceano")
add("badge.first", "First Scoop", "İlk Scoop", "Primer scoop", "Erster Scoop", "Premier scoop", "Primo scoop", "Primeiro scoop")
add("badge.loading", "Fully Loaded", "Yükleme Tamam", "Carga completa", "Voll geladen", "Charge terminée", "Carico completato", "Saturação completa")
add("badge.container", "Tub Finished", "Kutu Bitti", "Bote terminado", "Dose leer", "Pot terminé", "Barattolo finito", "Pote finalizado")
add("badge.month", "Perfect Month", "Kusursuz Ay", "Mes perfecto", "Perfekter Monat", "Mois parfait", "Mese perfetto", "Mês perfeito")

add("badge.creatine_detail %lld",
    P("%lld day of creatine in a row", "%lld days of creatine in a row"),
    "%lld gün üst üste kreatin",
    P("%lld día seguido de creatina", "%lld días seguidos de creatina"),
    P("%lld Tag Kreatin am Stück", "%lld Tage Kreatin am Stück"),
    P("%lld jour de créatine d’affilée", "%lld jours de créatine d’affilée"),
    P("%lld giorno di creatina di fila", "%lld giorni di creatina di fila"),
    P("%lld dia seguido de creatina", "%lld dias seguidos de creatina"))
add("badge.water_detail %lld",
    P("Water goal hit %lld day in a row", "Water goal hit %lld days in a row"),
    "%lld gün üst üste su hedefi",
    P("Objetivo de agua %lld día seguido", "Objetivo de agua %lld días seguidos"),
    P("Wasserziel %lld Tag am Stück erreicht", "Wasserziel %lld Tage am Stück erreicht"),
    P("Objectif d’eau atteint %lld jour d’affilée", "Objectif d’eau atteint %lld jours d’affilée"),
    P("Obiettivo d’acqua raggiunto %lld giorno di fila", "Obiettivo d’acqua raggiunto %lld giorni di fila"),
    P("Meta de água batida %lld dia seguido", "Meta de água batida %lld dias seguidos"))
add("badge.first_detail", "Your first creatine log", "İlk kreatin kaydın", "Tu primer registro de creatina",
    "Dein erster Kreatin-Eintrag", "Votre première prise de créatine", "La tua prima creatina registrata",
    "Seu primeiro registro de creatina")
add("badge.loading_detail", "Every day of your loading phase, on time", "Yükleme fazının her günü, zamanında",
    "Cada día de tu fase de carga, a tiempo", "Jeden Tag deiner Ladephase, pünktlich",
    "Chaque jour de votre phase de charge, à temps", "Ogni giorno della fase di carico, puntuale",
    "Todos os dias da sua saturação, no horário")
add("badge.container_detail", "You finished a whole tub", "Bir kutuyu bitirdin", "Terminaste un bote entero",
    "Du hast eine ganze Dose aufgebraucht", "Vous avez fini un pot entier", "Hai finito un barattolo intero",
    "Você terminou um pote inteiro")
add("badge.month_detail", "Creatine every day of a month", "Bir ayın her günü kreatin",
    "Creatina todos los días de un mes", "Kreatin an jedem Tag eines Monats", "Créatine chaque jour d’un mois",
    "Creatina ogni giorno di un mese", "Creatina todos os dias de um mês")

# ── Rozetler ekranı ────────────────────────────────────────
add("badges.title", "Badges", "Rozetler", "Insignias", "Abzeichen", "Badges", "Badge", "Medalhas")
add("badges.all", "All", "Tümü", "Todas", "Alle", "Tous", "Tutti", "Todas")
add("badges.rule_note",
    "Only days logged on the day count. Days added later from the calendar don’t.",
    "Sadece o gün girilen kayıtlar sayılır. Takvimden sonradan eklenen günler sayılmaz.",
    "Solo cuentan los días registrados ese mismo día. Los añadidos después desde el calendario, no.",
    "Nur am selben Tag erfasste Tage zählen. Später im Kalender nachgetragene nicht.",
    "Seuls les jours notés le jour même comptent. Ceux ajoutés plus tard depuis le calendrier, non.",
    "Contano solo i giorni registrati in giornata. Quelli aggiunti dopo dal calendario no.",
    "Só contam os dias registrados no próprio dia. Os adicionados depois pelo calendário, não.")
add("badges.next %@", "Next: %@", "Sıradaki: %@", "Siguiente: %@", "Als Nächstes: %@", "Prochain : %@", "Prossimo: %@", "Próxima: %@")
add("badges.days_left %lld",
    P("%lld day to go", "%lld days to go"), "%lld gün kaldı",
    P("Falta %lld día", "Faltan %lld días"), P("Noch %lld Tag", "Noch %lld Tage"),
    P("Encore %lld jour", "Encore %lld jours"), P("Manca %lld giorno", "Mancano %lld giorni"),
    P("Falta %lld dia", "Faltam %lld dias"))
add("badges.all_streaks", "Every streak badge earned. Legend.", "Tüm seri rozetleri senin. Efsane.",
    "Todas las insignias de racha conseguidas. Leyenda.", "Alle Serien-Abzeichen geholt. Legende.",
    "Tous les badges de série obtenus. Légende.", "Tutti i badge di serie ottenuti. Leggenda.",
    "Todas as medalhas de sequência conquistadas. Lenda.")
add("badges.earned %lld %lld",
    "%1$lld of %2$lld badges earned", "%2$lld rozetten %1$lld tanesi kazanıldı",
    "%1$lld de %2$lld insignias conseguidas", "%1$lld von %2$lld Abzeichen erhalten",
    "%1$lld badges obtenus sur %2$lld", "%1$lld badge su %2$lld ottenuti", "%1$lld de %2$lld medalhas conquistadas")
add("badges.earned_on %@", "Earned on %@", "%@ tarihinde kazanıldı", "Conseguida el %@", "Erhalten am %@",
    "Obtenu le %@", "Ottenuto il %@", "Conquistada em %@")
add("celebrate.one", "NEW BADGE", "YENİ ROZET", "NUEVA INSIGNIA", "NEUES ABZEICHEN", "NOUVEAU BADGE", "NUOVO BADGE", "NOVA MEDALHA")
add("celebrate.many %lld", "%lld NEW BADGES", "%lld YENİ ROZET", "%lld INSIGNIAS NUEVAS", "%lld NEUE ABZEICHEN",
    "%lld NOUVEAUX BADGES", "%lld NUOVI BADGE", "%lld NOVAS MEDALHAS")

# ── Paylaşım kartı ─────────────────────────────────────────
add("share.button", "Share", "Paylaş", "Compartir", "Teilen", "Partager", "Condividi", "Compartilhar")
add("share.streak_button", "Share streak", "Seriyi paylaş", "Compartir racha", "Serie teilen", "Partager la série",
    "Condividi serie", "Compartilhar sequência")
add("share.new_badge", "NEW BADGE", "YENİ ROZET", "NUEVA INSIGNIA", "NEUES ABZEICHEN", "NOUVEAU BADGE", "NUOVO BADGE", "NOVA MEDALHA")
add("share.streak_title", "CREATINE STREAK", "KREATİN SERİSİ", "RACHA DE CREATINA", "KREATIN-SERIE",
    "SÉRIE DE CRÉATINE", "SERIE DI CREATINA", "SEQUÊNCIA DE CREATINA")
add("share.streak_days", "days in a row", "gün üst üste", "días seguidos", "Tage am Stück", "jours d’affilée",
    "giorni di fila", "dias seguidos")
add("share.streak_tagline", "One scoop a day.", "Her gün tek scoop.", "Un scoop al día.", "Ein Scoop am Tag.",
    "Un scoop par jour.", "Uno scoop al giorno.", "Um scoop por dia.")
add("share.last_4_weeks", "Last 4 weeks", "Son 4 hafta", "Últimas 4 semanas", "Letzte 4 Wochen",
    "4 dernières semaines", "Ultime 4 settimane", "Últimas 4 semanas")
add("share.footer", "Creatine & water tracker · App Store", "Kreatin ve su takibi · App Store",
    "Creatina y agua · App Store", "Kreatin- & Wasser-Tracker · App Store", "Suivi créatine et eau · App Store",
    "Creatina e acqua · App Store", "Creatina e água · App Store")

# ── Raporlar ───────────────────────────────────────────────
add("reports.title", "Reports", "Raporlar", "Informes", "Berichte", "Rapports", "Report", "Relatórios")
add("reports.week", "Week", "Hafta", "Semana", "Woche", "Semaine", "Settimana", "Semana")
add("reports.month", "Month", "Ay", "Mes", "Monat", "Mois", "Mese", "Mês")
add("reports.locked_title", "All charts with OneScoop+", "Tüm grafikler OneScoop+ ile",
    "Todos los gráficos con OneScoop+", "Alle Diagramme mit OneScoop+", "Tous les graphiques avec OneScoop+",
    "Tutti i grafici con OneScoop+", "Todos os gráficos com OneScoop+")
add("reports.locked_button", "Unlock", "Kilidi aç", "Desbloquear", "Freischalten", "Débloquer", "Sblocca", "Desbloquear")
add("reports.same_as_before", "Same as last week", "Geçen haftayla aynı", "Igual que la semana pasada",
    "Wie letzte Woche", "Comme la semaine dernière", "Come la settimana scorsa", "Igual à semana passada")
add("reports.water_goal", "Water goal", "Su hedefi", "Objetivo de agua", "Wasserziel", "Objectif d’eau",
    "Obiettivo acqua", "Meta de água")
add("reports.saturation", "Muscle creatine saturation", "Kas kreatin doygunluğu", "Saturación de creatina muscular",
    "Muskel-Kreatinsättigung", "Saturation musculaire en créatine", "Saturazione muscolare di creatina",
    "Saturação de creatina muscular")
add("reports.saturation_sub", "ESTIMATE · LAST 30 DAYS", "TAHMİNİ MODEL · SON 30 GÜN", "ESTIMACIÓN · ÚLTIMOS 30 DÍAS",
    "SCHÄTZUNG · LETZTE 30 TAGE", "ESTIMATION · 30 DERNIERS JOURS", "STIMA · ULTIMI 30 GIORNI", "ESTIMATIVA · ÚLTIMOS 30 DIAS")
add("reports.saturation_to_full %lld",
    P("Keep going daily and you’ll be fully saturated in about %lld day.",
      "Keep going daily and you’ll be fully saturated in about %lld days."),
    "Kesintisiz devam edersen yaklaşık %lld gün içinde tam doygunluğa ulaşırsın.",
    P("Si sigues a diario, estarás saturado en unos %lld día.", "Si sigues a diario, estarás saturado en unos %lld días."),
    P("Bleib täglich dran und du bist in etwa %lld Tag voll gesättigt.", "Bleib täglich dran und du bist in etwa %lld Tagen voll gesättigt."),
    P("En continuant chaque jour, saturation complète dans environ %lld jour.", "En continuant chaque jour, saturation complète dans environ %lld jours."),
    P("Continua ogni giorno e sarai saturo in circa %lld giorno.", "Continua ogni giorno e sarai saturo in circa %lld giorni."),
    P("Continue todo dia e você estará saturado em cerca de %lld dia.", "Continue todo dia e você estará saturado em cerca de %lld dias."))
add("reports.saturation_full", "You’re fully saturated. Keep it up.", "Tam doygunluktasın. Böyle devam.",
    "Estás totalmente saturado. Sigue así.", "Du bist voll gesättigt. Weiter so.",
    "Vous êtes pleinement saturé. Continuez.", "Sei completamente saturo. Continua così.",
    "Você está totalmente saturado. Continue assim.")
add("reports.water_sub %@ %@", "AVG %1$@ L · %2$@ OF GOAL", "ORTALAMA %1$@ L · HEDEFİN %2$@",
    "MEDIA %1$@ L · %2$@ DEL OBJETIVO", "Ø %1$@ L · %2$@ DES ZIELS", "MOY. %1$@ L · %2$@ DE L’OBJECTIF",
    "MEDIA %1$@ L · %2$@ DELL’OBIETTIVO", "MÉDIA %1$@ L · %2$@ DA META")
add("reports.daily", "Daily", "Günlük", "Diario", "Täglich", "Par jour", "Giornaliero", "Diário")
add("reports.average", "Average", "Ortalama", "Media", "Schnitt", "Moyenne", "Media", "Média")
add("reports.goal", "Goal", "Hedef", "Objetivo", "Ziel", "Objectif", "Obiettivo", "Meta")
add("reports.goal_days %lld",
    P("You hit your goal on %lld day.", "You hit your goal on %lld days."),
    "Hedefe %lld gün ulaştın.",
    P("Alcanzaste el objetivo %lld día.", "Alcanzaste el objetivo %lld días."),
    P("Ziel an %lld Tag erreicht.", "Ziel an %lld Tagen erreicht."),
    P("Objectif atteint %lld jour.", "Objectif atteint %lld jours."),
    P("Obiettivo raggiunto %lld giorno.", "Obiettivo raggiunto %lld giorni."),
    P("Meta batida em %lld dia.", "Meta batida em %lld dias."))
add("reports.hours", "When you take it", "Alım saati dağılımı", "Cuándo la tomas", "Wann du es nimmst",
    "Quand vous la prenez", "Quando la prendi", "Quando você toma")
add("reports.hours_sub %lld",
    P("LAST 30 DAYS · %lld LOG", "LAST 30 DAYS · %lld LOGS"), "SON 30 GÜN · %lld KAYIT",
    P("ÚLTIMOS 30 DÍAS · %lld REGISTRO", "ÚLTIMOS 30 DÍAS · %lld REGISTROS"),
    P("LETZTE 30 TAGE · %lld EINTRAG", "LETZTE 30 TAGE · %lld EINTRÄGE"),
    P("30 DERNIERS JOURS · %lld PRISE", "30 DERNIERS JOURS · %lld PRISES"),
    P("ULTIMI 30 GIORNI · %lld REGISTRAZIONE", "ULTIMI 30 GIORNI · %lld REGISTRAZIONI"),
    P("ÚLTIMOS 30 DIAS · %lld REGISTRO", "ÚLTIMOS 30 DIAS · %lld REGISTROS"))
add("reports.hours_note %@ %@",
    "%1$@ of your logs fall between %2$@. A steady time makes the habit stick.",
    "Kayıtlarının %1$@ kadarı %2$@ arasında. Düzenli saat, alışkanlığı kalıcı yapar.",
    "El %1$@ de tus registros está entre %2$@. Una hora fija afianza el hábito.",
    "%1$@ deiner Einträge liegen zwischen %2$@. Eine feste Zeit festigt die Gewohnheit.",
    "%1$@ de vos prises ont lieu entre %2$@. Une heure régulière ancre l’habitude.",
    "Il %1$@ delle registrazioni è tra le %2$@. Un orario fisso consolida l’abitudine.",
    "%1$@ dos seus registros ficam entre %2$@. Um horário fixo firma o hábito.")
add("reports.consistency", "Consistency", "Tutarlılık", "Constancia", "Beständigkeit", "Régularité", "Costanza", "Constância")
add("reports.total_creatine", "Total creatine", "Toplam kreatin", "Creatina total", "Kreatin gesamt",
    "Créatine totale", "Creatina totale", "Creatina total")
add("reports.days %lld", P("%lld day", "%lld days"), "%lld gün", P("%lld día", "%lld días"), P("%lld Tag", "%lld Tage"),
    P("%lld jour", "%lld jours"), P("%lld giorno", "%lld giorni"), P("%lld dia", "%lld dias"))
add("reports.creatine_calendar", "Creatine calendar", "Kreatin takvimi", "Calendario de creatina", "Kreatin-Kalender",
    "Calendrier créatine", "Calendario creatina", "Calendário de creatina")
add("reports.water_heatmap", "Water heatmap", "Su ısı haritası", "Mapa de calor del agua", "Wasser-Heatmap",
    "Carte de chaleur de l’eau", "Mappa di calore dell’acqua", "Mapa de calor da água")
add("reports.less", "Less", "Az", "Menos", "Weniger", "Moins", "Meno", "Menos")
add("reports.water_trend", "Water trend", "Su trendi", "Tendencia del agua", "Wasser-Trend", "Tendance de l’eau",
    "Andamento dell’acqua", "Tendência da água")
add("reports.average_l %@", "AVERAGE %@ L", "ORTALAMA %@ L", "MEDIA %@ L", "SCHNITT %@ L", "MOYENNE %@ L",
    "MEDIA %@ L", "MÉDIA %@ L")
add("reports.rolling", "7-day avg.", "7 gün ort.", "Media 7 días", "7-Tage-Ø", "Moy. 7 jours", "Media 7 gg", "Média 7 dias")
add("reports.weekday", "Water by weekday", "Haftanın günlerine göre su", "Agua por día de la semana",
    "Wasser nach Wochentag", "Eau par jour de la semaine", "Acqua per giorno della settimana", "Água por dia da semana")
add("reports.weekday_note %@ %@",
    "You drink most on %1$@ and least on %2$@.",
    "En çok %1$@, en az %2$@ günü içiyorsun.",
    "Bebes más los %1$@ y menos los %2$@.",
    "Am meisten trinkst du am %1$@, am wenigsten am %2$@.",
    "Vous buvez le plus le %1$@ et le moins le %2$@.",
    "Bevi di più il %1$@ e di meno il %2$@.",
    "Você bebe mais na %1$@ e menos na %2$@.")

# ── Hesaplayıcı ────────────────────────────────────────────
add("calc.title", "Creatine–water calculator", "Kreatin-su hesaplayıcı", "Calculadora creatina-agua",
    "Kreatin-Wasser-Rechner", "Calculateur créatine-eau", "Calcolatore creatina-acqua", "Calculadora creatina-água")
add("calc.result_label", "DAILY WATER", "GÜNLÜK SU", "AGUA DIARIA", "WASSER PRO TAG", "EAU PAR JOUR",
    "ACQUA AL GIORNO", "ÁGUA POR DIA")
add("calc.glasses %lld", P("about %lld glass", "about %lld glasses"), "yaklaşık %lld bardak",
    P("unos %lld vaso", "unos %lld vasos"), P("etwa %lld Glas", "etwa %lld Gläser"),
    P("environ %lld verre", "environ %lld verres"), P("circa %lld bicchiere", "circa %lld bicchieri"),
    P("cerca de %lld copo", "cerca de %lld copos"))
add("calc.weight", "Body weight", "Kilo", "Peso corporal", "Körpergewicht", "Poids", "Peso corporeo", "Peso corporal")
add("calc.from_health", "Get from Apple Health", "Apple Sağlık'tan al", "Obtener de Salud", "Aus Apple Health holen",
    "Récupérer depuis Santé", "Prendi da Salute", "Obter do Saúde")
add("calc.dose", "Creatine per day", "Günlük kreatin", "Creatina al día", "Kreatin pro Tag", "Créatine par jour",
    "Creatina al giorno", "Creatina por dia")
add("calc.my_dose %@", "Back to my dose (%@ g)", "Kendi dozuma dön (%@ g)", "Volver a mi dosis (%@ g)",
    "Zurück zu meiner Dosis (%@ g)", "Revenir à ma dose (%@ g)", "Torna alla mia dose (%@ g)", "Voltar à minha dose (%@ g)")
add("calc.workout", "Workout day", "Antrenman günü", "Día de entreno", "Trainingstag", "Jour d’entraînement",
    "Giorno di allenamento", "Dia de treino")
add("calc.base", "Base need", "Temel ihtiyaç", "Necesidad base", "Grundbedarf", "Besoin de base", "Fabbisogno base", "Necessidade base")
add("calc.creatine %@", "Creatine (%@ g)", "Kreatin (%@ g)", "Creatina (%@ g)", "Kreatin (%@ g)", "Créatine (%@ g)",
    "Creatina (%@ g)", "Creatina (%@ g)")
add("calc.apply", "Make it my water goal", "Su hedefim yap", "Usar como objetivo de agua", "Als Wasserziel setzen",
    "En faire mon objectif d’eau", "Usa come obiettivo d’acqua", "Usar como meta de água")
add("calc.applied", "Water goal set", "Su hedefin ayarlandı", "Objetivo de agua guardado", "Wasserziel gesetzt",
    "Objectif d’eau défini", "Obiettivo d’acqua impostato", "Meta de água definida")
add("calc.disclaimer",
    "An estimate based on a common rule of thumb (35 ml per kg, plus 100 ml per gram of creatine). Not medical advice.",
    "Yaygın bir pratik kurala dayalı tahmindir (kilo başına 35 ml, kreatinin gramı başına 100 ml). Tıbbi tavsiye değildir.",
    "Estimación basada en una regla práctica común (35 ml por kg y 100 ml por gramo de creatina). No es consejo médico.",
    "Schätzung nach einer gängigen Faustregel (35 ml pro kg plus 100 ml pro Gramm Kreatin). Keine medizinische Beratung.",
    "Estimation selon une règle courante (35 ml par kg, plus 100 ml par gramme de créatine). Pas un avis médical.",
    "Stima basata su una regola pratica comune (35 ml per kg, più 100 ml per grammo di creatina). Non è un consiglio medico.",
    "Estimativa baseada em uma regra prática comum (35 ml por kg, mais 100 ml por grama de creatina). Não é conselho médico.")

# ── Porsiyonlar / ayarlar / bildirimler ────────────────────
add("today.portion %lld %lld %@", "Portion %1$lld of %2$lld · %3$@ g", "Porsiyon %1$lld/%2$lld · %3$@ g",
    "Porción %1$lld de %2$lld · %3$@ g", "Portion %1$lld von %2$lld · %3$@ g", "Portion %1$lld sur %2$lld · %3$@ g",
    "Porzione %1$lld di %2$lld · %3$@ g", "Porção %1$lld de %2$lld · %3$@ g")
add("settings.portions", "Split into portions", "Porsiyonlara böl", "Dividir en tomas", "In Portionen aufteilen",
    "Répartir en prises", "Dividi in porzioni", "Dividir em porções")
add("settings.portions_off", "Off", "Kapalı", "No", "Aus", "Non", "No", "Não")
add("settings.after_workout", "After workouts", "Antrenmandan sonra", "Después de entrenar", "Nach dem Training",
    "Après l’entraînement", "Dopo l’allenamento", "Depois do treino")
add("settings.after_workout_footer",
    "When a workout lands in Apple Health and you haven’t logged creatine yet, OneScoop reminds you.",
    "Apple Sağlık'a bir antrenman düştüğünde kreatinini henüz girmediysen OneScoop hatırlatır.",
    "Cuando un entreno llega a Salud y aún no registraste la creatina, OneScoop te lo recuerda.",
    "Wenn ein Training in Apple Health landet und du noch kein Kreatin erfasst hast, erinnert dich OneScoop.",
    "Quand une séance arrive dans Santé et que vous n’avez pas encore noté la créatine, OneScoop vous le rappelle.",
    "Quando un allenamento arriva in Salute e non hai ancora registrato la creatina, OneScoop te lo ricorda.",
    "Quando um treino chega ao Saúde e você ainda não registrou a creatina, o OneScoop te lembra.")
add("notif.after_workout", "Workout done. Did you take your creatine?", "Antrenman bitti. Kreatinini aldın mı?",
    "Entreno hecho. ¿Tomaste tu creatina?", "Training geschafft. Hast du dein Kreatin genommen?",
    "Séance terminée. Avez-vous pris votre créatine ?", "Allenamento finito. Hai preso la creatina?",
    "Treino feito. Tomou sua creatina?")
add("notif.supply_low", "Your creatine runs out in about a week. Time to restock.",
    "Kreatinin yaklaşık bir hafta sonra bitiyor. Yenisini almanın zamanı.",
    "Tu creatina se acaba en una semana. Hora de reponer.",
    "Dein Kreatin ist in etwa einer Woche leer. Zeit für Nachschub.",
    "Votre créatine sera épuisée dans une semaine environ. Pensez à en racheter.",
    "La tua creatina finisce tra circa una settimana. È ora di ricomprarla.",
    "Sua creatina acaba em cerca de uma semana. Hora de repor.")

# ── OneScoop+ ekranı ───────────────────────────────────────
add("plus.bullet_workout", "Creatine reminder after workouts", "Antrenmandan sonra kreatin hatırlatması",
    "Recordatorio de creatina tras entrenar", "Kreatin-Erinnerung nach dem Training",
    "Rappel de créatine après la séance", "Promemoria creatina dopo l’allenamento",
    "Lembrete de creatina depois do treino")
