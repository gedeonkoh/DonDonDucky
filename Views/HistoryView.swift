//
//  HistoryView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var activityStore: ActivityStore
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("hideDeleteConfirmation") private var hideDeleteConfirmation = false
    
    @State private var activityToDelete: Activity?
    @State private var showDeleteAlert = false
    @State private var dontShowAgain = false
    @State private var selectedActivity: Activity?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color("WorkTop"),
                        Color("WorkBottom")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Weekly Summary Header
                    weeklySummaryHeader
                
                if activityStore.activities.isEmpty {
                    emptyStateView
                } else {
                    activityListView
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Delete Activity?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    activityToDelete = nil
                    dontShowAgain = false
                }
                if !hideDeleteConfirmation {
                    Button("Don't Show Again") {
                        hideDeleteConfirmation = true
                        if let activity = activityToDelete {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                activityStore.deleteActivity(activity)
                            }
                        }
                        activityToDelete = nil
                    }
                }
                Button("Delete", role: .destructive) {
                    if let activity = activityToDelete {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            activityStore.deleteActivity(activity)
                        }
                    }
                    activityToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete this activity?")
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailView(activity: activity)
            }
        }
    }
    
    // MARK: - Weekly Summary Header
    
    private var weeklySummaryHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                    
                    Text(formatWeeklyDuration(getTotalWeekFocus()))
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("DuckYellow"), Color("DuckOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("focused")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                }
                
                Spacer()
                
                // Mini chart icon
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("DuckYellow").opacity(0.6), Color("DuckOrange").opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.8))
            )
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private func getTotalWeekFocus() -> TimeInterval {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
        
        return activityStore.activities
            .filter { $0.startTime >= weekAgo }
            .reduce(0) { $0 + $1.duration }
    }
    
    private func formatWeeklyDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("duck_resting")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .opacity(0.6)
            
            Text("No Activities Yet")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.7))
            
            Text("Start a focus session and\nyour activities will appear here!")
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
    }
    
    private var activityListView: some View {
        List {
            ForEach(groupedActivities.keys.sorted().reversed(), id: \.self) { date in
                Section {
                    ForEach(groupedActivities[date] ?? []) { activity in
                        ActivityCardView(activity: activity)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .onTapGesture {
                                selectedActivity = activity
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    handleDelete(activity: activity)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(Color("DuckOrange"))
                        
                    Text(formatSectionDate(date))
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.6))
                        .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.bottom, 80)
    }
    
    private var groupedActivities: [String: [Activity]] {
        Dictionary(grouping: activityStore.activities) { activity in
            activity.formattedDate
        }
    }
    
    private func formatSectionDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        
        if let date = formatter.date(from: dateString) {
            if Calendar.current.isDateInToday(date) {
                return "Today"
            } else if Calendar.current.isDateInYesterday(date) {
                return "Yesterday"
            }
        }
        return dateString
    }
    
    private func handleDelete(activity: Activity) {
        if hideDeleteConfirmation {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                activityStore.deleteActivity(activity)
            }
        } else {
            activityToDelete = activity
            showDeleteAlert = true
        }
    }
}

// MARK: - Activity Card View

struct ActivityCardView: View {
    let activity: Activity
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Emoji icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color("DuckYellow"), Color("DuckOrange")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(activity.emoji)
                    .font(.system(size: 24))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.name)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                
                HStack(spacing: 16) {
                    // Start time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(activity.formattedStartTime)
                    }
                    .font(.system(.caption, design: .rounded, weight: .regular))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                    
                    // Focus duration
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.caption2)
                        Text(activity.formattedDuration)
                    }
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(Color("DuckOrange"))
                    
                    // Break duration (if any)
                    if activity.breakDuration > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "cup.and.saucer")
                                .font(.caption2)
                            Text(activity.formattedBreakDuration)
                }
                .font(.system(.caption, design: .rounded, weight: .regular))
                        .foregroundColor(Color("BreakAccent1"))
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.2))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark
                    ? Color.white.opacity(0.1)
                    : Color.white.opacity(0.8)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Activity Detail View (Full Screen)

struct ActivityDetailView: View {
    let activity: Activity
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color("WorkTop"), Color("WorkBottom")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Pull down handle
                VStack(spacing: 8) {
                    Capsule()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                    
                    Text("Pull down to close")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3))
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with emoji and name
                        VStack(spacing: 16) {
                            Text(activity.emoji)
                                .font(.system(size: 70))
                            
                            Text(activity.name)
                                .font(.system(.title, design: .rounded, weight: .heavy))
                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Date and Time Card
                        VStack(spacing: 16) {
                            // Day
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.title3)
                                    .foregroundColor(Color("DuckOrange"))
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Date")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                                    Text(activity.formattedDateRange)
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Text(activity.dayOfWeek)
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            }
                            
                            Divider()
                            
                            // Time Range
                            HStack {
                                Image(systemName: "clock")
                                    .font(.title3)
                                    .foregroundColor(Color("DuckOrange"))
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Time")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                                    Text("\(activity.formattedStartTime) → \(activity.formattedEndTime)")
                                        .font(.system(.body, design: .rounded, weight: .semibold))
                                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
                        )
                        .padding(.horizontal)
                        
                        // Duration Stats Card
                        VStack(spacing: 16) {
                            // Focus Time
                            HStack {
                                Image(systemName: "target")
                                    .font(.title3)
                                    .foregroundColor(Color("DuckOrange"))
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Focus Time")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                                    Text(activity.formattedDuration)
                                        .font(.system(.title2, design: .rounded, weight: .heavy))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color("DuckYellow"), Color("DuckOrange")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                }
                                
                                Spacer()
                            }
                            
                            if activity.breakDuration > 0 {
                                Divider()
                                
                                // Break Time
                                HStack {
                                    Image(systemName: "cup.and.saucer")
                                        .font(.title3)
                                        .foregroundColor(Color("BreakAccent1"))
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Break Time")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                                        Text(activity.formattedBreakDuration)
                                            .font(.system(.title2, design: .rounded, weight: .heavy))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color("BreakAccent1"), Color("BreakAccent2")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
                        )
                        .padding(.horizontal)
                        
                        // Focus/Break Pie Chart - SPREAD OUT LIKE OTHER BOXES
                        if activity.breakDuration > 0 {
                            VStack(spacing: 20) {
                                Text("Time Distribution")
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 40) {
                                    // Pie chart - LARGER
                                    ZStack {
                                        Circle()
                                            .stroke(Color("BreakAccent1").opacity(0.3), lineWidth: 24)
                                            .frame(width: 140, height: 140)
                                        
                                        Circle()
                                            .trim(from: 0, to: activity.focusPercentage / 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color("DuckYellow"), Color("DuckOrange")],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                style: StrokeStyle(lineWidth: 24, lineCap: .round)
                                            )
                                            .frame(width: 140, height: 140)
                                            .rotationEffect(.degrees(-90))
                                        
                                        VStack(spacing: 2) {
                                            Text("\(Int(activity.focusPercentage))%")
                                                .font(.system(.title2, design: .rounded, weight: .heavy))
                                                .foregroundStyle(
                                                    LinearGradient(
                                                        colors: [Color("DuckYellow"), Color("DuckOrange")],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                            Text("focus")
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                                        }
                                    }
                                    
                                    // Legend - SPREAD OUT MORE
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color("DuckYellow"), Color("DuckOrange")],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 16, height: 16)
                                            Text("Focus")
                                                .font(.system(.body, design: .rounded, weight: .medium))
                                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.7))
                                            Text("\(Int(activity.focusPercentage))%")
                                                .font(.system(.body, design: .rounded, weight: .bold))
                                                .foregroundColor(Color("DuckOrange"))
                                        }
                                        
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(Color("BreakAccent1"))
                                                .frame(width: 16, height: 16)
                                            Text("Break")
                                                .font(.system(.body, design: .rounded, weight: .medium))
                                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.7))
                                            Text("\(Int(activity.breakPercentage))%")
                                                .font(.system(.body, design: .rounded, weight: .bold))
                                                .foregroundColor(Color("BreakAccent1"))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(20) // MORE PADDING TO SPREAD OUT
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
                            )
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .offset(y: dragOffset)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    HistoryView()
        .environmentObject(ActivityStore())
}
