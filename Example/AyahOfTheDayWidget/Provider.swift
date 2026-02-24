import WidgetKit
import MushafImad

struct Provider: TimelineProvider {

    init() {
        // Initialize Realm in read-only mode for the widget
        try? RealmService.shared.initializeForWidget()
    }

    // اختيار آية بناءً على التاريخ
    private func ayahForDate(_ date: Date) -> Ayah {
        if let verse = RealmService.shared.getRandomAyah(for: date),
           let chapter = verse.chapter {
            return Ayah(
                text: verse.textWithoutTashkil.isEmpty ? verse.text : verse.textWithoutTashkil,
                surahName: chapter.arabicTitle,
                surahNumber: chapter.number,
                ayahNumber: verse.number
            )
        }
        
        // Fallback ayah if Realm fails
        return Ayah(text: "إِنَّ مَعَ الْعُسْرِ يُسْرًا", surahName: "الشرح", surahNumber: 94, ayahNumber: 6)
    }

    func placeholder(in context: Context) -> AyahEntry {
        AyahEntry(date: Date(), ayah: ayahForDate(Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (AyahEntry) -> Void) {
        completion(AyahEntry(date: Date(), ayah: ayahForDate(Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AyahEntry>) -> Void) {
        let date = Date()
        let entry = AyahEntry(date: date, ayah: ayahForDate(date))

        // تحديث عند منتصف الليل
        let nextUpdate = Calendar.current.nextDate(after: date, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) ?? date.addingTimeInterval(86400)

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}