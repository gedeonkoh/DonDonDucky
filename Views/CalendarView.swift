//
//  CalendarView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

enum CalendarViewMode {
    case day
    case week
}

struct CalendarView: View {
    @EnvironmentObject var calendarStore: CalendarStore
    @EnvironmentObject var todoStore: TodoStore
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedDate = Date()
    @State private var viewMode: CalendarViewMode = .day
    @State private var showAddEvent = false
    @State private var showAddCountdown = false
    @State private var selectedEvent: CalendarEvent?
    @State private var dragOffset: CGFloat = 0
    @State private var isAllDayCollapsed = false // Track collapse state for All Day section
    
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
                
                VStack(spacing: 0) {
                    // View mode toggle
                    viewModeToggle
                    
                    // Calendar header
                    calendarHeader
                    
                    // Calendar content
                    if viewMode == .day {
                        dayView
                    } else {
                        weekView
                    }
                }
                .padding(.bottom, 80)
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                    Button(action: { showAddEvent = true }) {
                            Label("Add Event", systemImage: "calendar.badge.plus")
                        }
                        Button(action: { showAddCountdown = true }) {
                            Label("Add Countdown", systemImage: "timer")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("DuckYellow"), Color("DuckOrange")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .sheet(isPresented: $showAddEvent) {
                AddEventView(selectedDate: selectedDate)
            }
            .sheet(isPresented: $showAddCountdown) {
                AddCountdownView(selectedDate: selectedDate)
            }
            .sheet(item: $selectedEvent) { event in
                if event.isCountdownEvent {
                    EditCountdownView(event: event)
                } else {
                EditEventView(event: event)
                }
            }
        }
    }
    
    // MARK: - View Mode Toggle
    
    private var viewModeToggle: some View {
        HStack(spacing: 4) {
            ForEach([("Day", CalendarViewMode.day), ("Week", CalendarViewMode.week)], id: \.0) { title, mode in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        viewMode = mode
                    }
                }) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(viewMode == mode
                            ? .white
                            : (colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            viewMode == mode
                                ? Capsule().fill(
                                    LinearGradient(
                                        colors: [Color("DuckYellow"), Color("DuckOrange")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                : nil
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
        )
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Calendar Header
    
    private var calendarHeader: some View {
        HStack {
            Button(action: { navigateDate(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(Color("DuckOrange"))
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(headerDateText)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                
                if viewMode == .day {
                    Text(dayOfWeekText)
                        .font(.system(.subheadline, design: .rounded, weight: .regular))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                }
            }
            
            Spacer()
            
            Button(action: { navigateDate(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(Color("DuckOrange"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        navigateDate(by: 1)
                    } else if value.translation.width > 50 {
                        navigateDate(by: -1)
                    }
                }
        )
    }
    
    private var headerDateText: String {
        let formatter = DateFormatter()
        if viewMode == .day {
            formatter.dateFormat = "MMMM d, yyyy"
        } else {
            formatter.dateFormat = "MMMM yyyy"
        }
        return formatter.string(from: selectedDate)
    }
    
    private var dayOfWeekText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayName = formatter.string(from: selectedDate)
        
        if Calendar.current.isDateInToday(selectedDate) {
            return "Today • \(dayName)"
        } else if Calendar.current.isDateInTomorrow(selectedDate) {
            return "Tomorrow • \(dayName)"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday • \(dayName)"
        }
        return dayName
    }
    
    private func navigateDate(by value: Int) {
        withAnimation(.spring(response: 0.3)) {
            if viewMode == .day {
                selectedDate = Calendar.current.date(byAdding: .day, value: value, to: selectedDate) ?? selectedDate
            } else {
                selectedDate = Calendar.current.date(byAdding: .weekOfYear, value: value, to: selectedDate) ?? selectedDate
            }
        }
    }
    
    // MARK: - Day View
    
    private var dayView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Full Day Events Section - Dedicated space at top (Collapsible)
                let allDayEvents = calendarStore.events(for: selectedDate).filter { $0.isAllDay }
                if !allDayEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        // Collapsible header
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isAllDayCollapsed.toggle()
                            }
                        }) {
                            HStack {
                                Text("All Day")
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                                
                                Spacer()
                                
                                Image(systemName: isAllDayCollapsed ? "chevron.down" : "chevron.up")
                                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                        }
                        .buttonStyle(.plain)
                        
                        // Events (collapsible)
                        if !isAllDayCollapsed {
                            ForEach(allDayEvents) { event in
                                EventCard(event: event) {
                                    selectedEvent = event
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.bottom, 16)
                    
                    // Divider between All Day and calendar
                    Divider()
                        .background(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                // Hourly events
                ForEach(0..<24, id: \.self) { hour in
                    HourRowView(
                        hour: hour,
                        events: eventsForHour(hour).filter { !$0.isAllDay }, // Exclude all-day events from hourly view
                        todos: todosForHour(hour),
                        onEventTap: { event in
                            selectedEvent = event
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        navigateDate(by: 1)
                    } else if value.translation.width > 50 {
                        navigateDate(by: -1)
                    }
                }
        )
    }
    
    private func eventsForHour(_ hour: Int) -> [CalendarEvent] {
        let calendar = Calendar.current
        return calendarStore.events(for: selectedDate).filter { event in
            !event.isAllDay && calendar.component(.hour, from: event.startDate) == hour
        }
    }
    
    private func todosForDate(_ date: Date) -> [TodoItem] {
        let calendar = Calendar.current
        return todoStore.items.filter { item in
            guard let dueDate = item.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date) && !item.isCompleted
        }
    }
    
    private func todosForHour(_ hour: Int) -> [TodoItem] {
        let calendar = Calendar.current
        return todosForDate(selectedDate).filter { item in
            guard let dueDate = item.dueDate else { return false }
            let itemHour = calendar.component(.hour, from: dueDate)
            return itemHour == hour
        }
    }
    
    // MARK: - Week View
    
    private var weekView: some View {
        VStack(spacing: 10) {
            // Week day headers
            HStack(spacing: 4) {
                ForEach(weekDays, id: \.self) { date in
                    WeekDayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasEvents: !calendarStore.events(for: date).isEmpty
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDate = date
                            // Stay in week view - don't switch to day view
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Events for selected day
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Full Day Events Section - Dedicated space at top (NO TITLE in week view)
                    let allDayEvents = calendarStore.events(for: selectedDate).filter { $0.isAllDay }
                    if !allDayEvents.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            // REMOVED: "All Day" title for week view
                            
                            ForEach(allDayEvents) { event in
                                EventCard(event: event) {
                                    selectedEvent = event
                                }
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Regular Calendar Events (non-all-day)
                    ForEach(calendarStore.events(for: selectedDate).filter { !$0.isAllDay }) { event in
                        EventCard(event: event) {
                            selectedEvent = event
                        }
                    }
                    
                    // Todo Items with deadlines
                    ForEach(todosForDate(selectedDate)) { todo in
                        TodoDeadlineCard(todo: todo)
                    }
                    
                    if calendarStore.events(for: selectedDate).isEmpty && todosForDate(selectedDate).isEmpty {
                        VStack(spacing: 15) {
                            Image("duck_resting")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .opacity(0.5)
                            
                            Text("No events")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
}

// MARK: - Supporting Views

struct HourRowView: View {
    let hour: Int
    let events: [CalendarEvent]
    let todos: [TodoItem]
    let onEventTap: (CalendarEvent) -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Time label
            Text(hourString)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                .frame(width: 50, alignment: .trailing)
            
            // Hour line and events/todos
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1))
                    .frame(height: 1)
                
                ForEach(events) { event in
                    EventBlock(event: event)
                        .onTapGesture {
                            onEventTap(event)
                        }
                }
                
                // Show todos for this hour
                ForEach(todos) { todo in
                    TodoBlock(todo: todo)
                }
            }
        }
        .frame(minHeight: 60)
    }
    
    private var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}

struct EventBlock: View {
    let event: CalendarEvent
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(event.color.color)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                
                Text(event.formattedTimeRange)
                    .font(.system(.caption2, design: .rounded, weight: .regular))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(event.color.color.opacity(0.15))
        )
    }
}

struct WeekDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(dayName)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                
                Text(dayNumber)
                    .font(.system(.title3, design: .rounded, weight: isSelected ? .heavy : .medium))
                    .foregroundColor(isSelected
                        ? .white
                        : (isToday ? Color("DuckOrange") : (colorScheme == .dark ? .white : .black.opacity(0.8)))
                    )
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected
                                ? LinearGradient(
                                    colors: [Color("DuckYellow"), Color("DuckOrange")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
                            )
                    )
                
                Circle()
                    .fill(hasEvents ? Color("DuckOrange") : Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

struct EventCard: View {
    let event: CalendarEvent
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(event.color.color)
                    .frame(width: 4)
                    .cornerRadius(2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                    
                    Text(event.formattedTimeRange)
                        .font(.system(.caption, design: .rounded, weight: .regular))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TodoDeadlineCard: View {
    let todo: TodoItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.title3)
                .foregroundColor(Color("DuckOrange"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Task due: \(todo.title)")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                
                if let dueDate = todo.dueDate {
                    Text(formatDueTime(dueDate))
                        .font(.system(.caption, design: .rounded, weight: .regular))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
    
    private func formatDueTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct TodoBlock: View {
    let todo: TodoItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .font(.caption)
                .foregroundColor(Color("DuckOrange"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Task due: \(todo.title)")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("DuckOrange").opacity(0.15))
        )
    }
}

#Preview {
    CalendarView()
        .environmentObject(CalendarStore())
        .environmentObject(TodoStore())
}

