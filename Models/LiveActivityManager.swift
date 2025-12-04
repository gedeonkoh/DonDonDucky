//
//  LiveActivityManager.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import ActivityKit
import SwiftUI
import Combine

@available(iOS 16.1, *)
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: ActivityItem<FocusTimerActivityAttributes>?
    
    private init() {}
    
    func startActivity(activityName: String, emoji: String, elapsedTime: TimeInterval, breakTime: TimeInterval, timerState: TimerState, startTime: Date) {
        // Check authorization status
        let authInfo = ActivityAuthorizationInfo()
        print("🔴 Live Activity Authorization Status:")
        print("   - areActivitiesEnabled: \(authInfo.areActivitiesEnabled)")
        print("   - frequentPushesEnabled: \(authInfo.frequentPushesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            print("❌ Live Activities are not enabled in system settings")
            return
        }
        
        // End any existing activity first
        if let existingActivity = currentActivity {
            Task {
                await existingActivity.activity.end(using: existingActivity.activity.contentState, dismissalPolicy: .immediate)
            }
            currentActivity = nil
        }
        
        let attributes = FocusTimerActivityAttributes(
            activityName: activityName,
            emoji: emoji
        )
        
        let contentState = FocusTimerActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            breakTime: breakTime,
            timerState: timerState == .onBreak ? "onBreak" : "running",
            startTime: startTime
        )
        
        print("🟡 Attempting to start Live Activity...")
        print("   - Activity Name: \(activityName)")
        print("   - Emoji: \(emoji)")
        print("   - Timer State: \(timerState == .onBreak ? "onBreak" : "running")")
        
        do {
            // Request Live Activity without push notifications
            // pushType: nil means we'll update it locally, no push needed
            let activity = try ActivityKit.Activity<FocusTimerActivityAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil  // No push notifications required
            )
            
            print("✅ Live Activity started successfully!")
            print("   - Activity ID: \(activity.id)")
            print("   - Activity State: \(activity.activityState)")
            
            currentActivity = ActivityItem(activity: activity)
            
            // Start updating the activity
            updateActivity(elapsedTime: elapsedTime, breakTime: breakTime, timerState: timerState)
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
            print("   Error details: \(error.localizedDescription)")
            print("   Error type: \(type(of: error))")
        }
    }
    
    func updateActivity(elapsedTime: TimeInterval, breakTime: TimeInterval, timerState: TimerState) {
        guard let activity = currentActivity?.activity else { return }
        
        let contentState = FocusTimerActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            breakTime: breakTime,
            timerState: timerState == .onBreak ? "onBreak" : "running",
            startTime: activity.contentState.startTime
        )
        
        Task {
            await activity.update(using: contentState)
        }
    }
    
    func endActivity() {
        guard let activity = currentActivity?.activity else { return }
        
        Task {
            let finalState = FocusTimerActivityAttributes.ContentState(
                elapsedTime: activity.contentState.elapsedTime,
                breakTime: activity.contentState.breakTime,
                timerState: activity.contentState.timerState,
                startTime: activity.contentState.startTime
            )
            
            await activity.end(using: finalState, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
    
    func stopActivity() {
        endActivity()
    }
}

// Helper class to hold activity reference
@available(iOS 16.1, *)
class ActivityItem<T: ActivityAttributes>: ObservableObject {
    let activity: ActivityKit.Activity<T>
    
    init(activity: ActivityKit.Activity<T>) {
        self.activity = activity
    }
}

