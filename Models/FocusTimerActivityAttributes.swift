//
//  FocusTimerActivityAttributes.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import ActivityKit

struct FocusTimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedTime: TimeInterval
        var breakTime: TimeInterval
        var timerState: String // "running" or "onBreak"
        var startTime: Date
        
        var formattedTime: String {
            let time = timerState == "onBreak" ? breakTime : elapsedTime
            let hours = Int(time) / 3600
            let minutes = (Int(time) % 3600) / 60
            let seconds = Int(time) % 60
            
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }
    
    var activityName: String
    var emoji: String
}

