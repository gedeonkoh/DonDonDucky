//
//  CalendarSyncManager.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import EventKit
import SwiftUI
import Combine

class CalendarSyncManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var isSyncing = false
    
    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    func requestAccess() async -> Bool {
        do {
            let status = try await eventStore.requestAccess(to: .event)
            await MainActor.run {
                authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            }
            return status
        } catch {
            await MainActor.run {
                authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            }
            return false
        }
    }
    
    func syncEventToAppleCalendar(_ event: CalendarEvent) async throws {
        guard authorizationStatus == .authorized else {
            throw CalendarSyncError.notAuthorized
        }
        
        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = event.title
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.isAllDay = event.isAllDay
        ekEvent.notes = event.notes
        ekEvent.calendar = eventStore.defaultCalendarForNewEvents
        
        // Set reminder
        if let notifyBefore = event.notifyBefore {
            let alarm = EKAlarm(relativeOffset: -Double(notifyBefore * 60))
            ekEvent.addAlarm(alarm)
        }
        
        do {
            try eventStore.save(ekEvent, span: .thisEvent)
        } catch {
            throw CalendarSyncError.saveFailed(error)
        }
    }
    
    func loadEventsFromAppleCalendar(startDate: Date, endDate: Date) async throws -> [EKEvent] {
        guard authorizationStatus == .authorized else {
            throw CalendarSyncError.notAuthorized
        }
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        return eventStore.events(matching: predicate)
    }
    
    func deleteEventFromAppleCalendar(eventIdentifier: String) async throws {
        guard authorizationStatus == .authorized else {
            throw CalendarSyncError.notAuthorized
        }
        
        if let ekEvent = eventStore.event(withIdentifier: eventIdentifier) {
            try eventStore.remove(ekEvent, span: .thisEvent)
        }
    }
}

enum CalendarSyncError: LocalizedError {
    case notAuthorized
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized"
        case .saveFailed(let error):
            return "Failed to save to calendar: \(error.localizedDescription)"
        }
    }
}

