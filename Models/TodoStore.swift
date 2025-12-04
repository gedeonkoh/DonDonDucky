//
//  TodoStore.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import SwiftUI
import Combine

class TodoStore: ObservableObject {
    @Published var items: [TodoItem] = []
    @Published var groups: [TodoGroup] = []
    
    private let itemsKey = "SavedTodoItems"
    private let groupsKey = "SavedTodoGroups"
    
    init() {
        loadData()
        
        // Create default group if none exist
        if groups.isEmpty {
            let defaultGroup = TodoGroup(name: "My Tasks", icon: "checkmark.circle.fill", colorName: "orange", order: 0)
            groups.append(defaultGroup)
            saveGroups()
        }
    }
    
    // MARK: - Items
    
    func addItem(_ item: TodoItem) {
        items.insert(item, at: 0)
        saveItems()
    }
    
    func updateItem(_ item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveItems()
        }
    }
    
    func deleteItem(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }
    
    func toggleComplete(_ item: TodoItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted.toggle()
            saveItems()
        }
    }
    
    func items(for groupId: UUID) -> [TodoItem] {
        items.filter { $0.groupId == groupId }
    }
    
    func pendingItems(for groupId: UUID) -> [TodoItem] {
        items.filter { $0.groupId == groupId && !$0.isCompleted }
    }
    
    func completedItems(for groupId: UUID) -> [TodoItem] {
        items.filter { $0.groupId == groupId && $0.isCompleted }
    }
    
    var allPendingItems: [TodoItem] {
        items.filter { !$0.isCompleted }
    }
    
    var todayItems: [TodoItem] {
        let calendar = Calendar.current
        return items.filter { item in
            guard let dueDate = item.dueDate else { return false }
            return calendar.isDateInToday(dueDate) && !item.isCompleted
        }
    }
    
    // MARK: - Groups
    
    func addGroup(_ group: TodoGroup) {
        guard groups.count < 10 else { return } // Max 10 groups
        var newGroup = group
        newGroup.order = groups.count
        groups.append(newGroup)
        saveGroups()
    }
    
    func updateGroup(_ group: TodoGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
            saveGroups()
        }
    }
    
    func deleteGroup(_ group: TodoGroup) {
        // Delete all items in the group first
        items.removeAll { $0.groupId == group.id }
        groups.removeAll { $0.id == group.id }
        saveItems()
        saveGroups()
    }
    
    var canAddMoreGroups: Bool {
        groups.count < 10
    }
    
    // MARK: - Persistence
    
    private func saveItems() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: itemsKey)
        }
    }
    
    private func saveGroups() {
        if let encoded = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(encoded, forKey: groupsKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            items = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: groupsKey),
           let decoded = try? JSONDecoder().decode([TodoGroup].self, from: data) {
            groups = decoded.sorted { $0.order < $1.order }
        }
    }
}

