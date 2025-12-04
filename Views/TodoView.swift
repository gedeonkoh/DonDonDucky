//
//  TodoView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

struct TodoView: View {
    @EnvironmentObject var todoStore: TodoStore
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showAddGroup = false
    @State private var showAddTask = false
    @State private var selectedGroupId: UUID?
    @State private var newTaskTitle = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color("WorkTop"), Color("WorkBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(todoStore.groups) { group in
                            TodoGroupCard(
                                group: group,
                                items: todoStore.items(for: group.id),
                                onAddTask: {
                                    selectedGroupId = group.id
                                    showAddTask = true
                                }
                            )
                        }
                        
                        // Add Group Button
                        if todoStore.canAddMoreGroups {
                            Button(action: { showAddGroup = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Add Group")
                                        .font(.system(.headline, design: .rounded, weight: .semibold))
                                }
                                .foregroundColor(Color("DuckOrange"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color("DuckOrange"), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("To-Do")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddGroup) {
                AddGroupSheet()
            }
            .sheet(isPresented: $showAddTask) {
                if let groupId = selectedGroupId {
                    AddTaskSheet(groupId: groupId)
                }
            }
        }
    }
}

struct TodoGroupCard: View {
    @EnvironmentObject var todoStore: TodoStore
    @Environment(\.colorScheme) var colorScheme
    
    let group: TodoGroup
    let items: [TodoItem]
    let onAddTask: () -> Void
    
    @State private var isExpanded = true
    @State private var showEditGroup = false
    @State private var showDeleteAlert = false
    
    var pendingItems: [TodoItem] {
        items.filter { !$0.isCompleted }
    }
    
    var completedItems: [TodoItem] {
        items.filter { $0.isCompleted }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: { withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }}) {
                HStack {
                    Image(systemName: group.icon)
                        .font(.title2)
                        .foregroundColor(group.color)
                    
                    Text(group.name)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(pendingItems.count)")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(group.color))
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                Button(action: onAddTask) {
                    Label("Add Task", systemImage: "plus")
                }
                Button(action: { showEditGroup = true }) {
                    Label("Edit Group", systemImage: "pencil")
                }
                if todoStore.groups.count > 1 {
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete Group", systemImage: "trash")
                    }
                }
            }
            
            // Tasks
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(pendingItems) { item in
                        TodoItemRow(item: item)
                    }
                    
                    // Add task button
                    Button(action: onAddTask) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(group.color)
                            Text("Add task")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    
                    // Completed section
                    if !completedItems.isEmpty {
                        Divider()
                            .padding(.horizontal)
                        
                        DisclosureGroup {
                            ForEach(completedItems) { item in
                                TodoItemRow(item: item)
                            }
                        } label: {
                            Text("Completed (\(completedItems.count))")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showEditGroup) {
            EditGroupSheet(group: group)
        }
        .alert("Delete Group?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                todoStore.deleteGroup(group)
            }
        } message: {
            Text("This will delete the group and all tasks in it.")
        }
    }
}

struct TodoItemRow: View {
    @EnvironmentObject var todoStore: TodoStore
    @Environment(\.colorScheme) var colorScheme
    
    let item: TodoItem
    @State private var offset: CGFloat = 0
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack {
            // Background actions - only show when swiping
            HStack(spacing: 0) {
                // Complete action (revealed when swiping LEFT)
                if offset < 0 && !item.isCompleted {
                    Color.green
                        .overlay(
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(.trailing, 20)
                            }
                        )
                        .frame(width: abs(min(offset, 0)))
                }
                
                Spacer()
                
                // Delete action (revealed when swiping RIGHT)
                if offset > 0 {
                    Color.red
                    .overlay(
                        HStack {
                            Image(systemName: "trash.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                    .padding(.leading, 20)
                                Spacer()
                        }
                    )
                        .frame(width: max(offset, 0))
                }
            }
            
            // Main content
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        todoStore.toggleComplete(item)
                    }
                }) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(item.isCompleted ? .green : (colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3)))
                }
                
                Text(item.title)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(item.isCompleted
                        ? (colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3))
                        : (colorScheme == .dark ? .white : .black.opacity(0.8))
                    )
                    .strikethrough(item.isCompleted)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color(white: 0.15) : Color.white)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        withAnimation(.interactiveSpring()) {
                        offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3)) {
                            if value.translation.width < -100 && !item.isCompleted {
                                // Swipe LEFT - complete
                                todoStore.toggleComplete(item)
                                offset = 0
                            } else if value.translation.width > 100 {
                                // Swipe RIGHT - delete
                                todoStore.deleteItem(item)
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}

struct AddGroupSheet: View {
    @EnvironmentObject var todoStore: TodoStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var name = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "orange"
    
    let icons = ["folder.fill", "star.fill", "heart.fill", "book.fill", "briefcase.fill", "house.fill", "cart.fill", "graduationcap.fill"]
    let colors = ["orange", "blue", "green", "purple", "pink", "red", "yellow", "teal"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("WorkTop"), Color("WorkBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image("duck_happy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    TextField("Group Name", text: $name)
                        .font(.system(.body, design: .rounded))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                        )
                    
                    // Icon picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Button(action: { selectedIcon = icon }) {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? .white : (colorScheme == .dark ? .white : .black.opacity(0.6)))
                                        .frame(width: 50, height: 50)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedIcon == icon ? Color("DuckOrange") : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)))
                                        )
                                }
                            }
                        }
                    }
                    
                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Button(action: { selectedColor = color }) {
                                    Circle()
                                        .fill(colorForName(color))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: saveGroup) {
                        Text("Create Group")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color("DuckYellow"), Color("DuckOrange")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.6 : 1)
                }
                .padding()
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("DuckOrange"))
                }
            }
        }
    }
    
    private func colorForName(_ name: String) -> Color {
        switch name {
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
    
    private func saveGroup() {
        let group = TodoGroup(name: name, icon: selectedIcon, colorName: selectedColor)
        todoStore.addGroup(group)
        dismiss()
    }
}

struct EditGroupSheet: View {
    @EnvironmentObject var todoStore: TodoStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let group: TodoGroup
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    
    let icons = ["folder.fill", "star.fill", "heart.fill", "book.fill", "briefcase.fill", "house.fill", "cart.fill", "graduationcap.fill"]
    let colors = ["orange", "blue", "green", "purple", "pink", "red", "yellow", "teal"]
    
    init(group: TodoGroup) {
        self.group = group
        _name = State(initialValue: group.name)
        _selectedIcon = State(initialValue: group.icon)
        _selectedColor = State(initialValue: group.colorName)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("WorkTop"), Color("WorkBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Group Name", text: $name)
                        .font(.system(.body, design: .rounded))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                        )
                    
                    // Icon picker
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .white : (colorScheme == .dark ? .white : .black.opacity(0.6)))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedIcon == icon ? Color("DuckOrange") : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)))
                                    )
                            }
                        }
                    }
                    
                    // Color picker
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(colorForName(color))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: updateGroup) {
                        Text("Save Changes")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color("DuckYellow"), Color("DuckOrange")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .disabled(name.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("DuckOrange"))
                }
            }
        }
    }
    
    private func colorForName(_ name: String) -> Color {
        switch name {
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
    
    private func updateGroup() {
        var updated = group
        updated.name = name
        updated.icon = selectedIcon
        updated.colorName = selectedColor
        todoStore.updateGroup(updated)
        dismiss()
    }
}

struct AddTaskSheet: View {
    @EnvironmentObject var todoStore: TodoStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let groupId: UUID
    
    @State private var title = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("WorkTop"), Color("WorkBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image("duck_happy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                    
                    TextField("Task title", text: $title)
                        .font(.system(.body, design: .rounded))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                        )
                    
                    Toggle("Due Date", isOn: $hasDueDate)
                        .tint(Color("DuckOrange"))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                        )
                    
                    if hasDueDate {
                        DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                            )
                    }
                    
                    Spacer()
                    
                    Button(action: saveTask) {
                        Text("Add Task")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color("DuckYellow"), Color("DuckOrange")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .disabled(title.isEmpty)
                    .opacity(title.isEmpty ? 0.6 : 1)
                }
                .padding()
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color("DuckOrange"))
                }
            }
        }
    }
    
    private func saveTask() {
        let item = TodoItem(
            title: title,
            dueDate: hasDueDate ? dueDate : nil,
            groupId: groupId
        )
        todoStore.addItem(item)
        dismiss()
    }
}

#Preview {
    TodoView()
        .environmentObject(TodoStore())
}

