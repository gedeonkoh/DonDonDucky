//
//  TodoItem.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import SwiftUI

struct TodoItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var dueDate: Date?
    var groupId: UUID
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date(), dueDate: Date? = nil, groupId: UUID) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.groupId = groupId
    }
}

struct TodoGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var colorName: String
    var order: Int
    
    init(id: UUID = UUID(), name: String, icon: String = "folder.fill", colorName: String = "orange", order: Int = 0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.order = order
    }
    
    var color: Color {
        switch colorName {
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "yellow": return .yellow
        case "teal": return .teal
        default: return .orange
        }
    }
}

