// WaterTrackerApp.swift
import SwiftUI
import CoreData

@main
struct WaterTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    ensureSettingsExist()
                }
        }
    }
    
    private func ensureSettingsExist() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Settings> = Settings.fetchRequest()
        do {
            let results = try context.fetch(request)
            if results.isEmpty {
                let settings = Settings(context: context)
                settings.dailyGoal = 2000
                settings.notificationsEnabled = false
                // Установим временные интервалы по умолчанию (8:00 и 22:00)
                let calendar = Calendar.current
                let start = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
                let end = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
                settings.notificationIntervalStart = start
                settings.notificationIntervalEnd = end
                settings.remindIfInactive = true
                settings.remindIfGoalNotMet = true
                try context.save()
            }
        } catch {
            print("Ошибка инициализации настроек: \(error)")
        }
    }
}
