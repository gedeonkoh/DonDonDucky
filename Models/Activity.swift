//
//  Activity.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation

struct Activity: Identifiable, Codable {
    let id: UUID
    let name: String
    let emoji: String
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let breakDuration: TimeInterval
    
    init(id: UUID = UUID(), name: String = "Focus Session", emoji: String = "🎯", startTime: Date, endTime: Date? = nil, duration: TimeInterval, breakDuration: TimeInterval = 0) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.startTime = startTime
        self.endTime = endTime ?? startTime.addingTimeInterval(duration + breakDuration)
        self.duration = duration
        self.breakDuration = breakDuration
    }
    
    var totalDuration: TimeInterval {
        duration + breakDuration
    }
    
    var focusPercentage: Double {
        guard totalDuration > 0 else { return 100 }
        return (duration / totalDuration) * 100
    }
    
    var breakPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return (breakDuration / totalDuration) * 100
    }
    
    var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: endTime)
    }
    
    var spansMultipleDays: Bool {
        !Calendar.current.isDate(startTime, inSameDayAs: endTime)
    }
    
    var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        if spansMultipleDays {
            return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        }
        return formatter.string(from: startTime)
    }
    
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: startTime)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var formattedBreakDuration: String {
        let minutes = Int(breakDuration) / 60
        let seconds = Int(breakDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: startTime)
    }
}
