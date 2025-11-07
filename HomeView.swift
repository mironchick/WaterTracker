// HomeView.swift
import SwiftUI
import CoreData
import UserNotifications

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.timestamp, order: .reverse)],
        animation: .default
    )
    private var waterIntakes: FetchedResults<WaterIntake>
    
    @AppStorage("dailyGoal") private var dailyGoal: Int = 2000
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("reminderIntervalHours") private var reminderIntervalHours: Int = 2
    
    @State private var customAmount: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCelebration = false
    @State private var wasGoalReached = false
    @State private var showingSettings = false
    @State private var showingStatistics = false
    
    var consumedToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return waterIntakes
            .filter { $0.timestamp != nil && $0.timestamp! >= today }
            .reduce(0) { $0 + Int($1.amount) }
    }
    
    var progress: Double {
        let goal = Double(dailyGoal)
        return goal > 0 ? Double(consumedToday) / goal : 0.0
    }
    
    var todayIntakes: [WaterIntake] {
        let today = Calendar.current.startOfDay(for: Date())
        return waterIntakes.filter { intake in
            guard let timestamp = intake.timestamp else { return false }
            return Calendar.current.isDate(timestamp, inSameDayAs: today)
        }
    }
    
    var headerText: String {
        if consumedToday >= dailyGoal {
            return "Цель по воде выполнена"
        } else {
            return "Моя цель по воде"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 10) {
                    Text(headerText)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    
                    WaterPersonView(progress: progress)
                        .frame(width: 100, height: 200)
                    
                    Text("\(consumedToday) / \(dailyGoal) мл")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.vertical, 10)
                    
                    HStack(spacing: 12) {
                        ForEach([100, 200, 250, 500], id: \.self) { amount in
                            Button("\(amount) мл") {
                                addWater(amount: amount)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        TextField("Объём (мл)", text: $customAmount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        Button("Добавить") {
                            if let amount = Int(customAmount), amount > 0 {
                                addWater(amount: amount)
                                customAmount = ""
                            } else {
                                alertMessage = "Введите корректное положительное число"
                                showAlert = true
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    List {
                        ForEach(todayIntakes, id: \.self) { intake in
                            HStack {
                                Text("\(intake.amount) мл")
                                Spacer()
                                Text(formatTime(intake.timestamp))
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(PlainListStyle())
                    .padding(.horizontal)
                }
                .navigationBarHidden(true)
                .alert("Ошибка", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(alertMessage)
                }
                .onAppear {
                    requestNotificationPermission()
                }
                
                if showCelebration {
                    ConfettiView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .zIndex(1)
                        .onTapGesture {
                            showCelebration = false
                        }
                }
                
                // Кнопка настроек — в правом верхнем углу
                GeometryReader { geometry in
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .position(x: geometry.size.width - 30, y: 120)
                    .zIndex(10)
                }
                .ignoresSafeArea(.all, edges: .top)
                .sheet(isPresented: $showingSettings) {
                    GoalSettingsView(dailyGoal: $dailyGoal)
                }
                
                // Кнопка статистики — в левом верхнем углу
                GeometryReader { geometry in
                    Button(action: {
                        showingStatistics = true
                    }) {
                        Image(systemName: "chart.bar")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .position(x: 30, y: 120)
                    .zIndex(10)
                }
                .ignoresSafeArea(.all, edges: .top)
                .sheet(isPresented: $showingStatistics) {
                    StatisticsView()
                }
            }
            .onChange(of: consumedToday) { _ in
                let nowReached = consumedToday >= dailyGoal
                if !wasGoalReached && nowReached {
                    showCelebration = true
                    wasGoalReached = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        showCelebration = false
                    }
                } else if !nowReached {
                    wasGoalReached = false
                }
            }
        }
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Разрешение на уведомления получено")
            } else if let error = error {
                print("Ошибка запроса разрешения: \(error)")
            }
        }
    }
    
    private func scheduleHydrationReminder() {
        guard notificationsEnabled else { return }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["HydrationReminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Пора пить воду!"
        content.body = "Прошло уже \(reminderIntervalHours) \(pluralizeHours(reminderIntervalHours)) с последнего стакана. Не забывай пить воду 💧"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(reminderIntervalHours * 60 * 60),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: "HydrationReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка планирования напоминания: \(error)")
            }
        }
    }
    
    private func scheduleGoalReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["GoalReminder"])
        
        let calendar = Calendar.current
        let now = Date()
        let endOfDay = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!
        let timeUntilEnd = endOfDay.timeIntervalSince(now)
        
        if timeUntilEnd > 3600 && timeUntilEnd < 7200 {
            let content = UNMutableNotificationContent()
            content.title = "Скоро конец дня!"
            content.body = "Твоя цель по воде ещё не выполнена. Успей сегодня! 💪"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeUntilEnd, repeats: false)
            let request = UNNotificationRequest(identifier: "GoalReminder", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Ошибка планирования напоминания цели: \(error)")
                }
            }
        }
    }
    
    private func pluralizeHours(_ hours: Int) -> String {
        if hours == 1 {
            return "час"
        } else if hours >= 2 && hours <= 4 {
            return "часа"
        } else {
            return "часов"
        }
    }
    
    // MARK: - Actions
    
    private func addWater(amount: Int) {
        let newIntake = WaterIntake(context: viewContext)
        newIntake.amount = Int16(amount)
        newIntake.timestamp = Date()
        
        do {
            try viewContext.save()
            scheduleHydrationReminder()
            scheduleGoalReminder()
        } catch {
            alertMessage = "Ошибка сохранения: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let intake = todayIntakes[index]
            viewContext.delete(intake)
        }
        do {
            try viewContext.save()
            scheduleHydrationReminder()
            scheduleGoalReminder()
        } catch {
            alertMessage = "Ошибка удаления: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
