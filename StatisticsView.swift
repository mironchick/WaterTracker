// StatisticsView.swift
import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.timestamp, order: .reverse)],
        animation: .default
    )
    private var waterIntakes: FetchedResults<WaterIntake>
    
    // Вычисляем данные за последние 7 дней
    var last7DaysData: [(date: Date, amount: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var data: [(Date, Int)] = []
        
        // Проходим по последним 7 дням (включая сегодня)
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: -i, to: today)!
            let startOfDay = calendar.startOfDay(for: day)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let amount = waterIntakes
                .filter { intake in
                    guard let timestamp = intake.timestamp else { return false }
                    return timestamp >= startOfDay && timestamp < endOfDay
                }
                .reduce(0) { $0 + Int($1.amount) }
            
            data.append((day, amount))
        }
        
        // Сортируем от старых к новым
        return data.reversed()
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(last7DaysData, id: \.date) { dayData in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dayFormatter.string(from: dayData.date))
                                .font(.headline)
                            Text(weekdayFormatter.string(from: dayData.date))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("\(dayData.amount) мл")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Статистика")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }
    
    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }
}

#Preview {
    StatisticsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
