//
//  ContentView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .timer
    @State private var hideTabBar: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    enum Tab: CaseIterable {
        case timer
        case calendar
        case todo
        case history
        
        var icon: String {
            switch self {
            case .timer: return "timer"
            case .calendar: return "calendar"
            case .todo: return "checkmark.circle"
            case .history: return "clock.arrow.circlepath"
            }
        }
        
        var label: String {
            switch self {
            case .timer: return "Timer"
            case .calendar: return "Calendar"
            case .todo: return "To-Do"
            case .history: return "History"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            Group {
                switch selectedTab {
                case .timer:
                    MainView(hideTabBar: $hideTabBar)
                case .calendar:
                    CalendarView()
                case .todo:
                    TodoView()
                case .history:
                    HistoryView()
                }
            }
            
            // Custom Tab Bar with Liquid Glass effect - Hide when dashboard is open
            if !hideTabBar {
            customTabBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(tab: tab)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            GlassBackground()
        )
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.2), radius: 25, y: 12)
        .padding(.horizontal, 40) // Compressed on sides
        .padding(.bottom, 8) // More to bottom
    }
    
    private func tabButton(tab: Tab) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: selectedTab == tab ? .bold : .medium))
                    .symbolRenderingMode(.hierarchical)
                
                Text(tab.label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
            }
            .foregroundColor(selectedTab == tab
                ? (colorScheme == .dark ? .white : Color("DuckOrange"))
                : (colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Group {
                    if selectedTab == tab {
                        Capsule()
                            .fill(colorScheme == .dark
                                ? Color.white.opacity(0.18)
                                : Color("DuckYellow").opacity(0.25)
                            )
                            .padding(.horizontal, 2)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Liquid Glass Background Effect
struct GlassBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Frosted glass effect with capsule shape for more rounded corners
            if colorScheme == .dark {
                // Dark mode glass
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            } else {
                // Light mode glass
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.9),
                                        Color.white.opacity(0.5),
                                        Color.white.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.white.opacity(0.6), radius: 3, x: -1, y: -1)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ActivityStore())
        .environmentObject(UserManager())
        .environmentObject(CalendarStore())
        .environmentObject(TodoStore())
}
