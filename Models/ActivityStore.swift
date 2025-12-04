//
//  ActivityStore.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import SwiftUI
import Combine

class ActivityStore: ObservableObject {
    @Published var activities: [Activity] = []
    
    private let saveKey = "SavedActivities"
    
    init() {
        loadActivities()
    }
    
    func addActivity(_ activity: Activity) {
        activities.insert(activity, at: 0)
        saveActivities()
    }
    
    func deleteActivity(at indexSet: IndexSet) {
        activities.remove(atOffsets: indexSet)
        saveActivities()
    }
    
    func deleteActivity(_ activity: Activity) {
        activities.removeAll { $0.id == activity.id }
        saveActivities()
    }
    
    private let appGroupID = "group.inno.dondonducky"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
    
    private func saveActivities() {
        if let encoded = try? JSONEncoder().encode(activities) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
            // Also save to App Group for widgets
            sharedDefaults?.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadActivities() {
        if let data = UserDefaults.standard.data(forKey: saveKey) ?? sharedDefaults?.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Activity].self, from: data) {
            activities = decoded
        }
    }
}

