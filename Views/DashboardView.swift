//
//  DashboardView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var calendarStore: CalendarStore
    @EnvironmentObject var todoStore: TodoStore
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var activityStore: ActivityStore
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var streakManager = StreakManager.shared
    
    @State private var selectedDate = Date()
    @State private var dragOffset: CGFloat = 0
    @State private var showIDCard = false
    @State private var showSettings = false
    @State private var showStatsView = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header - Single line greeting
                    headerView
                    
                    // Streak Widget
                    streakWidget
                    
                    // ID Card Widget - Full Card Size
                    idCardWidget
                    
                    // Focus Time Graph Widget with break/focus
                    focusTimeGraphWidget
                    
                    // Calendar Widget with events
                    calendarWidget
                    
                    // Countdown Widget
                    countdownWidget
                    
                    // Tasks Widget - Separated by groups
                    tasksWidget
                    
                    // Upcoming Events Widget
                    upcomingEventsWidget
                    
                    // Settings Button at Bottom
                    Button(action: { showSettings = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                            Text("Settings")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                        }
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
                        )
                    }
                    .padding(.top, 20)
                }
                .padding()
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showIDCard) {
            IDCardPopup()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showStatsView) {
            StatsView()
        }
    }
    
    // MARK: - Header (Single Line)
    
    private var headerView: some View {
        HStack {
            // Single line greeting
            Text("\(userManager.greeting), \(userManager.firstName.isEmpty ? "Friend" : userManager.firstName)")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
            
            Spacer()
            
            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
            }
            
            // Profile picture or duck
            Button(action: { showIDCard = true }) {
                if let profileImage = userManager.profileImage {
                    profileImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Image("duck_happy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                }
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Streak Widget
    
    private var streakWidget: some View {
        HStack(spacing: 16) {
            // Fire icon
            Image("fire_icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                
                HStack(spacing: 4) {
                    Text("\(streakManager.currentStreak)")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("DuckYellow"), Color("DuckOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("days")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
                }
            }
            
            Spacer()
            
            // View Stats button
            Button(action: { showStatsView = true }) {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(Color("DuckOrange"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
    
    // MARK: - ID Card Widget (Full Card Size)
    
    private var idCardWidget: some View {
        Button(action: { showIDCard = true }) {
            VStack(spacing: 0) {
                // Card Header
                HStack {
                    // Logo using actual image
                    Image(logoImageNames[userManager.selectedLogoIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 24)
                    
                    Spacer()
                    
                    Image("duck_happy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            idCardColors[userManager.idCardColorIndex].opacity(0.3),
                            idCardColors[userManager.idCardColorIndex].opacity(0.15)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                
                // Dashed line
                Rectangle()
                    .fill(idCardColors[userManager.idCardColorIndex].opacity(0.3))
                    .frame(height: 1)
                
                // Card Body
            HStack(spacing: 12) {
                // Profile Picture
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                            .stroke(idCardColors[userManager.idCardColorIndex].opacity(0.5), lineWidth: 1.5)
                            .frame(width: 60, height: 75)
                    
                    if let profileImage = userManager.profileImage {
                        profileImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 71)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Image("duck_happy")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                    }
                }
                
                    VStack(alignment: .leading, spacing: 8) {
                        // Name
                        VStack(alignment: .leading, spacing: 2) {
                            Text("name")
                                .font(.system(size: 9, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                            Text(userManager.userName.isEmpty ? "---" : userManager.userName.uppercased())
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        }
                        
                        HStack(spacing: 16) {
                            // Birthday
                            VStack(alignment: .leading, spacing: 2) {
                                Text("birthday")
                                    .font(.system(size: 9, design: .rounded))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                                Text(userManager.formattedBirthday)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                            }
                    
                            // School
                    if !userManager.school.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("school")
                                        .font(.system(size: 9, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                                    Text(userManager.school.uppercased())
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                        .lineLimit(1)
                                }
                            }
                    }
                }
                
                Spacer()
                
                    VStack {
                    Text("Duck ID")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(idCardColors[userManager.idCardColorIndex])
                        
                        Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3))
                }
                    .padding(.vertical, 4)
            }
                .padding(12)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.95))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                    .stroke(idCardColors[userManager.idCardColorIndex].opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private let logoNames = ["Quack Time", "Focus Duck", "Study Buddy"]
    private let logoImageNames = ["logo_quacktime", "logo_focusduck", "logo_studybuddy"]
    private let idCardColors: [Color] = [.orange, .blue, .green, .purple, .pink, .red, .teal, .indigo]
    
    // MARK: - Focus Time Graph Widget
    
    private var focusTimeGraphWidget: some View {
        VStack(spacing: 0) {
            // Widget Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Color("DuckOrange"))
                Text("Focus Time")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                Spacer()
                
                Text("Last 7 days")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
            }
            .padding()
            
            Divider()
                .padding(.horizontal)
            
            // Graph with focus/break distinction
            FocusTimeGraph(data: getLast7DaysFocusData())
                .frame(height: 150)
                .padding()
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color("DuckYellow"), Color("DuckOrange")],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 10, height: 10)
                    Text("Focus")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color("BreakAccent1"))
                        .frame(width: 10, height: 10)
                    Text("Break")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                }
                
                Spacer()
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Totals
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total focus:")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                
                Text(formatDuration(getTotalWeekFocus()))
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("DuckYellow"), Color("DuckOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total break:")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                    
                    Text(formatDuration(getTotalWeekBreak()))
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundColor(Color("BreakAccent1"))
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.05), radius: 15, y: 5)
        )
    }
    
    private func getLast7DaysFocusData() -> [(String, TimeInterval, TimeInterval)] {
        let calendar = Calendar.current
        var data: [(String, TimeInterval, TimeInterval)] = []
        
        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            
            let dayActivities = activityStore.activities.filter { activity in
                calendar.isDate(activity.startTime, inSameDayAs: date)
            }
            
            let totalFocus = dayActivities.reduce(0) { $0 + $1.duration }
            let totalBreak = dayActivities.reduce(0) { $0 + $1.breakDuration }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            let dayName = formatter.string(from: date)
            
            data.append((dayName, totalFocus, totalBreak))
        }
        
        return data
    }
    
    private func getTotalWeekFocus() -> TimeInterval {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        
        return activityStore.activities
            .filter { $0.startTime >= weekAgo }
            .reduce(0) { $0 + $1.duration }
    }
    
    private func getTotalWeekBreak() -> TimeInterval {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        
        return activityStore.activities
            .filter { $0.startTime >= weekAgo }
            .reduce(0) { $0 + $1.breakDuration }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Calendar Widget
    
    private var calendarWidget: some View {
        VStack(spacing: 0) {
            // Widget Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color("DuckOrange"))
                Text("Calendar")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                Spacer()
                
                // Navigation arrows
                HStack(spacing: 16) {
                    Button(action: { navigateDate(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                            .foregroundColor(Color("DuckOrange"))
                    }
                    
                    Text(formattedDate)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                    
                    Button(action: { navigateDate(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color("DuckOrange"))
                    }
                }
            }
            .padding()
            
            Divider()
                .padding(.horizontal)
            
            // Mini week view
            HStack(spacing: 4) {
                ForEach(weekDates, id: \.self) { date in
                    MiniDayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasEvents: !calendarStore.events(for: date).isEmpty
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDate = date
                        }
                    }
                }
            }
            .padding()
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -50 {
                            navigateDate(by: 7)
                        } else if value.translation.width > 50 {
                            navigateDate(by: -7)
                        }
                    }
            )
            
            // Events for selected day - Always show section
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 8) {
                let dayEvents = calendarStore.events(for: selectedDate)
                
                if dayEvents.isEmpty {
                    HStack {
                        Text("No events for this day")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3))
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                } else {
                    ForEach(dayEvents.prefix(3)) { event in
                        MiniEventRow(event: event)
                    }
                    
                    if dayEvents.count > 3 {
                        Text("+\(dayEvents.count - 3) more")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(Color("DuckOrange"))
                            .padding(.horizontal)
                    }
                }
                }
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.05), radius: 15, y: 5)
        )
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private func navigateDate(by days: Int) {
        withAnimation(.spring(response: 0.3)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
        }
    }
    
    // MARK: - Countdown Widget
    
    private var countdownWidget: some View {
        let countdownEvents = calendarStore.events
            .filter { $0.isCountdownEvent && $0.startDate > Date() }
            .sorted { $0.startDate < $1.startDate }
            .prefix(5)
        
        return Group {
            if !countdownEvents.isEmpty {
                VStack(spacing: 0) {
                    // Widget Header
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(Color("DuckOrange"))
                        Text("Countdown")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        Spacer()
                    }
                    .padding()
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Countdown Events
                    VStack(spacing: 12) {
                        ForEach(Array(countdownEvents)) { event in
                            HStack(spacing: 12) {
                                // Emoji
                                if let emoji = event.emoji {
                                    Text(emoji)
                                        .font(.system(size: 32))
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color("DuckYellow").opacity(0.3), Color("DuckOrange").opacity(0.3)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock")
                                            .font(.caption2)
                                            .foregroundColor(Color("DuckOrange"))
                                        Text(event.timeUntilString)
                                            .font(.system(.caption, design: .rounded, weight: .bold))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color("DuckYellow"), Color("DuckOrange")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                        
                                        Text("•")
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.2))
                                        
                                        Text(event.formattedDate)
                                            .font(.system(.caption2, design: .rounded))
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.8))
                            )
                        }
                    }
                    .padding()
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.05), radius: 15, y: 5)
                )
            }
        }
    }
    
    // MARK: - Tasks Widget (Separated by Groups)
    
    private var tasksWidget: some View {
        VStack(spacing: 0) {
            // Widget Header
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(Color("DuckOrange"))
                Text("Tasks")
                    .font(.system(.headline, design: .rounded, weight: .heavy))
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                Spacer()
                
                Text("\(todoStore.allPendingItems.count) pending")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
            }
            .padding()
            
            if todoStore.allPendingItems.isEmpty {
                VStack(spacing: 10) {
                    Image("duck_resting")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .opacity(0.5)
                    
                    Text("All done!")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                }
                .padding()
            } else {
                Divider()
                    .padding(.horizontal)
                
                // Show tasks grouped by their groups
                VStack(spacing: 12) {
                    ForEach(todoStore.groups.prefix(3)) { group in
                        let groupPendingItems = todoStore.pendingItems(for: group.id)
                        
                        if !groupPendingItems.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                // Group header
                                HStack(spacing: 6) {
                                    Image(systemName: group.icon)
                                        .font(.caption)
                                        .foregroundColor(group.color)
                                    
                                    Text(group.name)
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                                    
                                    Spacer()
                                    
                                    Text("\(groupPendingItems.count)")
                                        .font(.system(.caption2, design: .rounded, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(group.color))
                                }
                                .padding(.horizontal)
                                
                                // Tasks for this group
                                ForEach(groupPendingItems.prefix(2)) { item in
                        MiniTaskRow(item: item)
                    }
                }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.05), radius: 15, y: 5)
        )
    }
    
    // MARK: - Upcoming Events Widget
    
    private var upcomingEventsWidget: some View {
        let upcomingEvents = calendarStore.events.filter { $0.startDate > Date() }.sorted { $0.startDate < $1.startDate }.prefix(3)
        
        return Group {
            if !upcomingEvents.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Color("DuckOrange"))
                        Text("Upcoming")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        Spacer()
                    }
                    .padding()
                    
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(upcomingEvents)) { event in
                            HStack {
                                Rectangle()
                                    .fill(event.color.color)
                                    .frame(width: 4)
                                    .cornerRadius(2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.title)
                                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                    
                                    Text(event.formattedDate + " - " + event.formattedTimeRange)
                                        .font(.system(.caption2, design: .rounded, weight: .regular))
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.05), radius: 15, y: 5)
                )
            }
        }
    }
}

// MARK: - Focus Time Graph

struct FocusTimeGraph: View {
    let data: [(String, TimeInterval, TimeInterval)] // (day, focus, break)
    @Environment(\.colorScheme) var colorScheme
    
    private var maxValue: TimeInterval {
        let maxTotal = data.map { $0.1 + $0.2 }.max() ?? 0
        return max(maxTotal, 60)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data, id: \.0) { day, focus, breakTime in
                VStack(spacing: 4) {
                    // Stacked bar (focus + break)
                    VStack(spacing: 1) {
                        // Break bar (top)
                        if breakTime > 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color("BreakAccent1"))
                                .frame(height: max(2, CGFloat(breakTime / maxValue) * 100))
                        }
                        
                        // Focus bar (bottom)
                        RoundedRectangle(cornerRadius: focus > 0 ? 4 : 2)
                        .fill(
                            LinearGradient(
                                colors: [Color("DuckYellow"), Color("DuckOrange")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                            .frame(height: max(4, CGFloat(focus / maxValue) * 100))
                            .opacity(focus > 0 ? 1 : 0.2)
                    }
                    
                    // Duration label
                    Text(formatShortDuration(focus + breakTime))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                    
                    // Day label
                    Text(day)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func formatShortDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h\(mins > 0 ? "\(mins)" : "")"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "-"
        }
    }
}

// MARK: - ID Card Popup

struct IDCardPopup: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var showEditor = false
    
    let logoNames = ["Quack Time", "Focus Duck", "Study Buddy"]
    let logoImageNames = ["logo_quacktime", "logo_focusduck", "logo_studybuddy"]
    let idCardColors: [Color] = [.orange, .blue, .green, .purple, .pink, .red, .teal, .indigo]
    
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
                
                VStack(spacing: 24) {
                    // ID Card - Full Size
                    VStack(spacing: 0) {
                        // Header with logo
                        HStack {
                            Image(logoImageNames[userManager.selectedLogoIndex])
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 30)
                            
                            Spacer()
                            
                            Image("duck_happy")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [
                                    idCardColors[userManager.idCardColorIndex].opacity(0.3),
                                    idCardColors[userManager.idCardColorIndex].opacity(0.15)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        
                        // Dashed separator
                        Rectangle()
                            .fill(idCardColors[userManager.idCardColorIndex].opacity(0.3))
                            .frame(height: 1)
                        
                        // Main content
                        HStack(spacing: 16) {
                            // Profile Picture
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(idCardColors[userManager.idCardColorIndex].opacity(0.5), lineWidth: 2)
                                    .frame(width: 90, height: 110)
                                
                                if let profileImage = userManager.profileImage {
                                    profileImage
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 86, height: 106)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    VStack(spacing: 4) {
                                        Image("duck_happy")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 60, height: 60)
                                        
                                        Text("No photo")
                                            .font(.system(size: 9, design: .rounded))
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3))
                                    }
                                }
                            }
                            
                            // Info
                            VStack(alignment: .leading, spacing: 12) {
                                // Name
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("name")
                                        .font(.system(size: 10, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                                    Text(userManager.userName.isEmpty ? "---" : userManager.userName.uppercased())
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                }
                                
                                HStack(spacing: 20) {
                                    // Birthday
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("birthday")
                                            .font(.system(size: 10, design: .rounded))
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                                        Text(userManager.formattedBirthday)
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                    }
                                    
                                    // Year Level
                                    if !userManager.yearLevel.isEmpty {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("year level")
                                                .font(.system(size: 10, design: .rounded))
                                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                                            Text(userManager.yearLevel.uppercased())
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                        }
                                    }
                                }
                                
                                // School
                                if !userManager.school.isEmpty {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("school")
                                            .font(.system(size: 10, design: .rounded))
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                                        Text(userManager.school.uppercased())
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.95))
                            .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(idCardColors[userManager.idCardColorIndex].opacity(0.2), lineWidth: 1)
                    )
                    
                    // Edit button
                    Button(action: { showEditor = true }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit Duck ID")
                        }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
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
                        .shadow(color: Color("DuckOrange").opacity(0.3), radius: 10, y: 5)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Duck ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(Color("DuckOrange"))
                }
            }
            .sheet(isPresented: $showEditor) {
                IDEditorView()
            }
        }
    }
}

// MARK: - Supporting Views

struct MiniDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                
                Text(dayNumber)
                    .font(.system(.subheadline, design: .rounded, weight: isSelected ? .heavy : .medium))
                    .foregroundColor(isSelected
                        ? .white
                        : (isToday ? Color("DuckOrange") : (colorScheme == .dark ? .white : .black.opacity(0.7)))
                    )
                    .frame(width: 32, height: 32)
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
                    .frame(width: 5, height: 5)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
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

struct MiniEventRow: View {
    let event: CalendarEvent
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(event.color.color)
                .frame(width: 8, height: 8)
            
            Text(event.title)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.7))
                .lineLimit(1)
            
            Spacer()
            
            Text(formatTime(event.startDate))
                .font(.system(.caption2, design: .rounded, weight: .regular))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
        }
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct MiniTaskRow: View {
    @EnvironmentObject var todoStore: TodoStore
    @Environment(\.colorScheme) var colorScheme
    
    let item: TodoItem
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Swipe actions background - only show when swiping
            HStack(spacing: 0) {
                // Complete action (LEFT swipe)
                if offset < 0 {
                    Color.green
                    .overlay(
                            HStack {
                                Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                                    .padding(.trailing, 15)
                            }
                    )
                        .frame(width: abs(min(offset, 0)))
                }
                
                Spacer()
                
                // Delete action (RIGHT swipe)
                if offset > 0 {
                    Color.red
                    .overlay(
                            HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                                    .padding(.leading, 15)
                                Spacer()
                            }
                    )
                        .frame(width: max(offset, 0))
                }
            }
            
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        todoStore.toggleComplete(item)
                    }
                }) {
                    Image(systemName: "circle")
                        .font(.body)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3))
                }
                
                Text(item.title)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.7))
                    .lineLimit(1)
                
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
                            if value.translation.width < -80 {
                                // Swipe LEFT - complete
                                todoStore.toggleComplete(item)
                            } else if value.translation.width > 80 {
                                // Swipe RIGHT - delete
                                todoStore.deleteItem(item)
                            }
                            offset = 0
                        }
                    }
            )
        }
        .frame(height: 44)
        .clipped()
    }
}

#Preview {
    DashboardView()
        .environmentObject(CalendarStore())
        .environmentObject(TodoStore())
        .environmentObject(UserManager())
        .environmentObject(ActivityStore())
}
