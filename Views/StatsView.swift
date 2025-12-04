//
//  StatsView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var activityStore: ActivityStore
    @EnvironmentObject var streakManager: StreakManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
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
                    VStack(spacing: 24) {
                        // Header
                        Text("Your Stats")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                            .padding(.top, 20)
                        
                        // Gamified Stats Board
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            // Current Streak Card
                            StatCard(
                                icon: "fire_icon",
                                title: "Current Streak",
                                value: "\(streakManager.currentStreak)",
                                subtitle: "days",
                                color: Color("DuckOrange"),
                                isCustomIcon: true
                            )
                            
                            // Longest Streak Card
                            StatCard(
                                icon: "trophy",
                                title: "Longest Streak",
                                value: "\(streakManager.longestStreak)",
                                subtitle: "days",
                                color: Color("DuckYellow")
                            )
                            
                            // Total Focus Time
                            StatCard(
                                icon: "clock.fill",
                                title: "Total Focus",
                                value: formatTotalMinutes(getTotalFocusMinutes()),
                                subtitle: "minutes",
                                color: Color.blue
                            )
                            
                            // Total Activities
                            StatCard(
                                icon: "checkmark.circle.fill",
                                title: "Activities",
                                value: "\(activityStore.activities.count)",
                                subtitle: "completed",
                                color: Color.green
                            )
                            
                            // Average Session
                            StatCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Avg Session",
                                value: formatAverageMinutes(getAverageSessionMinutes()),
                                subtitle: "minutes",
                                color: Color.purple
                            )
                            
                            // This Week
                            StatCard(
                                icon: "calendar",
                                title: "This Week",
                                value: formatTotalMinutes(getWeekFocusMinutes()),
                                subtitle: "minutes",
                                color: Color.pink
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(Color("DuckOrange"))
                }
            }
        }
    }
    
    private func getTotalFocusMinutes() -> Int {
        Int(activityStore.activities.reduce(0) { $0 + $1.duration } / 60)
    }
    
    private func getAverageSessionMinutes() -> Int {
        guard !activityStore.activities.isEmpty else { return 0 }
        return Int(getTotalFocusMinutes() / activityStore.activities.count)
    }
    
    private func getWeekFocusMinutes() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekActivities = activityStore.activities.filter { $0.startTime >= weekAgo }
        return Int(weekActivities.reduce(0) { $0 + $1.duration } / 60)
    }
    
    private func formatTotalMinutes(_ minutes: Int) -> String {
        if minutes >= 1000 {
            return String(format: "%.1fk", Double(minutes) / 1000.0)
        }
        return "\(minutes)"
    }
    
    private func formatAverageMinutes(_ minutes: Int) -> String {
        return "\(minutes)"
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    var isCustomIcon: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Group {
                if isCustomIcon {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(color)
                }
            }
            
            // Value
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Title
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
            
            // Subtitle
            Text(subtitle)
                .font(.system(.caption2, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
        )
    }
}

#Preview {
    StatsView()
        .environmentObject(ActivityStore())
        .environmentObject(StreakManager.shared)
}

