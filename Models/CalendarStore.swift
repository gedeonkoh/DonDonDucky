//
//  CalendarStore.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications
import UIKit
import EventKit

class CalendarStore: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var appleCalendarSyncEnabled: Bool = false
    
    private let saveKey = "SavedCalendarEvents"
    private let syncEnabledKey = "AppleCalendarSyncEnabled"
    private let syncManager = CalendarSyncManager()
    
    init() {
        loadEvents()
        requestNotificationPermission()
        appleCalendarSyncEnabled = UserDefaults.standard.bool(forKey: syncEnabledKey)
    }
    
    func addEvent(_ event: CalendarEvent) {
        events.append(event)
        saveEvents()
        scheduleNotification(for: event)
        
        // Sync to Apple Calendar if enabled
        if appleCalendarSyncEnabled {
            Task {
                do {
                    try await syncManager.syncEventToAppleCalendar(event)
                } catch {
                    print("Failed to sync to Apple Calendar: \(error)")
                }
            }
        }
    }
    
    func updateEvent(_ event: CalendarEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            // Cancel old notification
            cancelNotification(for: events[index])
            events[index] = event
            saveEvents()
            scheduleNotification(for: event)
            
            // Sync to Apple Calendar if enabled
            if appleCalendarSyncEnabled {
                Task {
                    do {
                        try await syncManager.syncEventToAppleCalendar(event)
                    } catch {
                        print("Failed to sync to Apple Calendar: \(error)")
                    }
                }
            }
        }
    }
    
    func deleteEvent(_ event: CalendarEvent) {
        cancelNotification(for: event)
        events.removeAll { $0.id == event.id }
        saveEvents()
    }
    
    func setAppleCalendarSync(_ enabled: Bool) {
        appleCalendarSyncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: syncEnabledKey)
        
        if enabled {
            Task {
                let granted = await syncManager.requestAccess()
                if granted {
                    // Load existing Apple Calendar events
                    await loadAppleCalendarEvents()
                } else {
                    await MainActor.run {
                        appleCalendarSyncEnabled = false
                        UserDefaults.standard.set(false, forKey: syncEnabledKey)
                    }
                }
            }
        }
    }
    
    func loadAppleCalendarEvents() async {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        
        do {
            let ekEvents = try await syncManager.loadEventsFromAppleCalendar(startDate: startDate, endDate: endDate)
            
            await MainActor.run {
                // Convert EKEvents to CalendarEvents
                for ekEvent in ekEvents {
                    // Check if event already exists (by title and date)
                    let exists = events.contains { event in
                        event.title == ekEvent.title &&
                        abs(event.startDate.timeIntervalSince(ekEvent.startDate)) < 60
                    }
                    
                    if !exists {
                        // Map EKEvent color to EventColor
                        let eventColor: EventColor = {
                            if let cgColor = ekEvent.calendar?.cgColor {
                                let uiColor = UIColor(cgColor: cgColor)
                                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                                uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                                
                                // Simple color mapping based on RGB values
                                if red > 0.7 && green > 0.3 && green < 0.6 && blue < 0.3 { return .orange }
                                if red < 0.3 && green > 0.3 && green < 0.7 && blue > 0.7 { return .blue }
                                if red < 0.3 && green > 0.7 && blue < 0.3 { return .green }
                                if red > 0.7 && green < 0.3 && blue < 0.3 { return .red }
                                if red > 0.7 && green > 0.7 && blue < 0.3 { return .yellow }
                                if red > 0.5 && green < 0.3 && blue > 0.7 { return .purple }
                            }
                            return .orange
                        }()
                        
                        // Get reminder time from alarms
                        var notifyBefore: Int? = nil
                        if let alarm = ekEvent.alarms?.first, alarm.relativeOffset < 0 {
                            notifyBefore = Int(abs(alarm.relativeOffset) / 60)
                        }
                        
                        let calendarEvent = CalendarEvent(
                            title: ekEvent.title,
                            startDate: ekEvent.startDate,
                            endDate: ekEvent.endDate,
                            color: eventColor,
                            isAllDay: ekEvent.isAllDay,
                            notes: ekEvent.notes ?? "",
                            notifyBefore: notifyBefore,
                            emoji: nil,
                            isCountdownEvent: false
                        )
                        
                        events.append(calendarEvent)
                    }
                }
                
                saveEvents()
            }
        } catch {
            print("Failed to load Apple Calendar events: \(error)")
        }
    }
    
    func events(for date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }.sorted { $0.startDate < $1.startDate }
    }
    
    func events(in range: ClosedRange<Date>) -> [CalendarEvent] {
        events.filter { event in
            range.contains(event.startDate) || range.contains(event.endDate)
        }.sorted { $0.startDate < $1.startDate }
    }
    
    private let appGroupID = "group.inno.dondonducky"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
            // Also save to App Group for widgets
            sharedDefaults?.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: saveKey) ?? sharedDefaults?.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data) {
            events = decoded
        }
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    private func scheduleNotification(for event: CalendarEvent) {
        guard let minutesBefore = event.notifyBefore else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Quack Time Reminder"
        content.body = "\(event.title) starts in \(minutesBefore) minutes!"
        content.sound = .default
        
        let triggerDate = event.startDate.addingTimeInterval(-Double(minutesBefore * 60))
        guard triggerDate > Date() else { return }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: event.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotification(for event: CalendarEvent) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.id.uuidString])
    }
}

