//
//  Persistence.swift
//  WaterTracker
//
//  Created by Мирон Дорогин on 26.10.2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Пример тестовых данных для предпросмотра
        let amounts = [200, 300, 500, 250]
        for (index, amount) in amounts.enumerated() {
            let intake = WaterIntake(context: viewContext)
            intake.amount = Int16(amount)
            // Сдвигаем время назад на несколько часов для наглядности
            intake.timestamp = Calendar.current.date(byAdding: .hour, value: -index, to: Date())!
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WaterTracker")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
