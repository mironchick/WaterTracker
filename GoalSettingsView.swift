// GoalSettingsView.swift
import SwiftUI

struct GoalSettingsView: View {
    @Binding var dailyGoal: Int
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("reminderIntervalHours") private var reminderIntervalHours: Int = 2
    
    @State private var goalText: String = ""
    private let intervalOptions = [1, 2, 3, 4] // часы
    
    var body: some View {
        NavigationView {
            Form {
                Section("Ежедневная цель") {
                    HStack {
                        TextField("Цель (мл)", text: $goalText)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("мл")
                    }
                }
                
                Section("Уведомления") {
                    Toggle("Включить напоминания", isOn: $notificationsEnabled)
                    
                    Picker("Интервал напоминаний", selection: $reminderIntervalHours) {
                        ForEach(intervalOptions, id: \.self) { hours in
                            Text("\(hours) час\(hours == 1 ? "" : hours < 5 ? "а" : "ов")")
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(!notificationsEnabled)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Готово") {
                        if let goal = Int(goalText), goal > 0 {
                            dailyGoal = goal
                        }
                    }
                }
            }
            .onAppear {
                goalText = "\(dailyGoal)"
            }
        }
    }
}

#Preview {
    GoalSettingsView(dailyGoal: .constant(2000))
}
