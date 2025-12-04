//
//  TimerStateStore.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import SwiftUI
import Combine

struct SavedTimerState: Codable {
    var timerState: String // "idle", "running", "onBreak"
    var elapsedTime: TimeInterval
    var breakTime: TimeInterval
    var sessionStartTime: Date?
    var lastSavedTime: Date
}

class TimerStateStore: ObservableObject {
    @Published var savedState: SavedTimerState?
    
    private let saveKey = "SavedTimerState"
    private let appGroupID = "group.inno.dondonducky"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    init() {
        loadState()
    }
    
    func saveState(timerState: TimerState, elapsedTime: TimeInterval, breakTime: TimeInterval, sessionStartTime: Date?) {
        let state = SavedTimerState(
            timerState: timerState == .idle ? "idle" : (timerState == .running ? "running" : "onBreak"),
            elapsedTime: elapsedTime,
            breakTime: breakTime,
            sessionStartTime: sessionStartTime,
            lastSavedTime: Date()
        )
        
        savedState = state
        
        if let encoded = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
            // Also save to App Group for widgets
            sharedDefaults?.set(encoded, forKey: saveKey)
        }
    }
    
    func loadState() {
        if let data = UserDefaults.standard.data(forKey: saveKey) ?? sharedDefaults?.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(SavedTimerState.self, from: data) {
            savedState = decoded
        }
    }
    
    func clearState() {
        savedState = nil
        UserDefaults.standard.removeObject(forKey: saveKey)
        sharedDefaults?.removeObject(forKey: saveKey)
    }
    
    func restoreTimerState() -> (TimerState, TimeInterval, TimeInterval, Date?)? {
        guard let state = savedState else { return nil }
        
        // Calculate elapsed time since last save
        let timeSinceSave = Date().timeIntervalSince(state.lastSavedTime)
        
        let restoredState: TimerState
        switch state.timerState {
        case "running":
            restoredState = .running
        case "onBreak":
            restoredState = .onBreak
        default:
            restoredState = .idle
        }
        
        var restoredElapsed = state.elapsedTime
        var restoredBreak = state.breakTime
        
        // Add time that passed while app was closed
        if restoredState == .running {
            restoredElapsed += timeSinceSave
        } else if restoredState == .onBreak {
            restoredBreak += timeSinceSave
        }
        
        return (restoredState, restoredElapsed, restoredBreak, state.sessionStartTime)
    }
}

