//
//  CalendarEvent.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import SwiftUI

struct CalendarEvent: Identifiable, Codable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var color: EventColor
    var isAllDay: Bool
    var notes: String
    var notifyBefore: Int? // minutes before to notify
    var emoji: String? // For countdown events only
    var isCountdownEvent: Bool // Whether this is a countdown event
    
    init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date, color: EventColor = .orange, isAllDay: Bool = false, notes: String = "", notifyBefore: Int? = 15, emoji: String? = nil, isCountdownEvent: Bool = false) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.color = color
        self.isAllDay = isAllDay
        self.notes = notes
        self.notifyBefore = notifyBefore
        self.emoji = emoji
        self.isCountdownEvent = isCountdownEvent
    }
    
    var hoursUntil: Int {
        let hours = Int(startDate.timeIntervalSinceNow) / 3600
        return max(0, hours)
    }
    
    var timeUntilString: String {
        let interval = startDate.timeIntervalSinceNow
        if interval <= 0 {
            return "Now"
        }
        
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var formattedTimeRange: String {
        if isAllDay {
            return "All Day"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: startDate)
    }
}

enum EventColor: String, Codable, CaseIterable {
    case orange
    case blue
    case green
    case purple
    case pink
    case red
    case yellow
    case teal
    
    var color: Color {
        switch self {
        case .orange: return Color.orange
        case .blue: return Color.blue
        case .green: return Color.green
        case .purple: return Color.purple
        case .pink: return Color.pink
        case .red: return Color.red
        case .yellow: return Color.yellow
        case .teal: return Color.teal
        }
    }
    
    var name: String {
        rawValue.capitalized
    }
}

