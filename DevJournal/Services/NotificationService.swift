//
//  NotificationService.swift
//  DevJournal
//

import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }
    
    func scheduleFocusReminder(at time: DateComponents) {
        let content = UNMutableNotificationContent()
        content.title = "Time for your DevJournal focus session 🚀"
        content.body = "Log what you built today and track your progress."
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(identifier: "devjournal_daily_focus", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["devjournal_daily_focus"])
    }
}
