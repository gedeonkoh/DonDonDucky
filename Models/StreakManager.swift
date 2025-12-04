//
//  StreakManager.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import SwiftUI
import Combine

class StreakManager: ObservableObject {
    static let shared = StreakManager()
    
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var lastStreakDate: Date?
    
    private let streakKey = "CurrentStreak"
    private let longestStreakKey = "LongestStreak"
    private let lastStreakDateKey = "LastStreakDate"
    private let streakDatesKey = "StreakDates" // Array of dates with streaks
    
    private let minimumFocusMinutes = 15.0 // 15 minutes minimum per day
    
    private init() {
        loadStreakData()
    }
    
    // Check if activity qualifies for streak (15+ minutes of focus)
    func qualifiesForStreak(activity: Activity) -> Bool {
        let focusMinutes = activity.duration / 60.0
        return focusMinutes >= minimumFocusMinutes
    }
    
    // Update streak when activity is saved
    func updateStreak(for activity: Activity) -> Bool {
        guard qualifiesForStreak(activity: activity) else {
            return false
        }
        
        let calendar = Calendar.current
        let activityDate = calendar.startOfDay(for: activity.startTime)
        let today = calendar.startOfDay(for: Date())
        
        // Check if we already counted this day
        if let lastDate = lastStreakDate,
           calendar.isDate(lastDate, inSameDayAs: activityDate) {
            // Already counted today, but update if this is a longer session
            return false
        }
        
        // Check if this is today or yesterday (to maintain streak)
        if let lastDate = lastStreakDate {
            let daysSince = calendar.dateComponents([.day], from: lastDate, to: activityDate).day ?? 0
            
            if daysSince == 0 {
                // Same day - update
                lastStreakDate = activityDate
                saveStreakData()
                return false // Don't show popup, already counted
            } else if daysSince == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else {
                // Streak broken - reset to 1
                currentStreak = 1
            }
        } else {
            // First streak ever
            currentStreak = 1
        }
        
        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        lastStreakDate = activityDate
        saveStreakData()
        
        // Return true if this is a new streak day (to show popup)
        return true
    }
    
    // Get streak message based on streak count
    func getStreakMessage(streakCount: Int) -> (header: String, subHeader: String) {
        let headers = [
            "Keep the momentum going! 🔥",
            "You're unstoppable! 💪",
            "Consistency is key! ⭐",
            "Building greatness, one day at a time! 🌟",
            "You're on fire! 🔥",
            "Every day counts! 📈",
            "Small steps, big results! 🚀",
            "You're crushing it! 💯",
            "The streak continues! ⚡",
            "Excellence is a habit! ✨"
        ]
        
        let subHeaders = [
            "Another streak in the books! Let's continue... the \(streakCount) day streak",
            "You're on fire! Welcome, \(streakCount) day streak!",
            "Incredible! \(streakCount) days of focus and counting!",
            "Amazing work! Your \(streakCount) day streak is inspiring!",
            "Unstoppable! \(streakCount) days strong and growing!",
            "Phenomenal! Keep the \(streakCount) day streak alive!",
            "Outstanding! \(streakCount) days of dedication!",
            "Remarkable! Your \(streakCount) day streak shows real commitment!",
            "Exceptional! \(streakCount) days and still going strong!",
            "Incredible! The \(streakCount) day streak continues!"
        ]
        
        let headerIndex = streakCount % headers.count
        let subHeaderIndex = streakCount % subHeaders.count
        
        return (headers[headerIndex], subHeaders[subHeaderIndex])
    }
    
    private func saveStreakData() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        if let lastDate = lastStreakDate {
            UserDefaults.standard.set(lastDate, forKey: lastStreakDateKey)
        }
    }
    
    private func loadStreakData() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
        lastStreakDate = UserDefaults.standard.object(forKey: lastStreakDateKey) as? Date
    }
}

