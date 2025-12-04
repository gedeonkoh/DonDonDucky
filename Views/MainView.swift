//
//  MainView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

struct MainView: View {
    @State private var showDashboard = false
    @State private var dragOffset: CGFloat = 0
    @State private var dashboardOffset: CGFloat = -UIScreen.main.bounds.height
    @State private var currentPage: Int = 0 // Track which page is visible (0 = timer, 1 = music)
    @Binding var hideTabBar: Bool // Binding to hide tab bar when dashboard is open
    
    let dashboardThreshold: CGFloat = 100
    
    init(hideTabBar: Binding<Bool> = .constant(false)) {
        _hideTabBar = hideTabBar
    }
    
    var body: some View {
        ZStack {
            // Timer View (main content)
            TimerView(hideTabBarForStreak: $hideTabBar)
                .offset(y: showDashboard ? UIScreen.main.bounds.height * 0.3 : 0)
                .scaleEffect(showDashboard ? 0.9 : 1.0)
                .blur(radius: showDashboard ? 5 : 0)
                .allowsHitTesting(!showDashboard)
                .onPreferenceChange(TimerView.CurrentPageKey.self) { page in
                    currentPage = page
                }
            
            // Pull indicator at top - SHIFTED UP SIGNIFICANTLY - ONLY SHOW ON TIMER VIEW
            if !showDashboard && currentPage == 0 {
                VStack {
                    PullIndicator()
                        .padding(.top, 20) // SHIFTED UP from 60 to 20
                    Spacer()
                }
            }
            
            // Dashboard overlay
            if showDashboard {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showDashboard = false
                            hideTabBar = false // Show tab bar when dashboard closes
                        }
                    }
                
                DashboardSheet(isPresented: $showDashboard, hideTabBar: $hideTabBar)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .gesture(
            DragGesture(minimumDistance: 3) // Reduced minimum distance for easier pulling
                .onChanged { value in
                    // Allow drag down from anywhere in top 30% of screen - EASIER TO PULL
                    if !showDashboard && value.startLocation.y < UIScreen.main.bounds.height * 0.3 && value.translation.height > 0 {
                        // Allow dragging down to show dashboard
                        dragOffset = min(value.translation.height, 200)
                    } else if showDashboard && value.translation.height < 0 {
                        // Allow dragging up to hide dashboard
                        dragOffset = max(value.translation.height, -200)
                    }
                }
                .onEnded { value in
                    if !showDashboard {
                        // Show dashboard if dragged down enough from top 30% - LOWER THRESHOLD
                        if value.startLocation.y < UIScreen.main.bounds.height * 0.3 && (value.translation.height > 50 || value.predictedEndTranslation.height > 80) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showDashboard = true
                                hideTabBar = true // Hide tab bar when dashboard opens
                            }
                        }
                    } else {
                        // Hide dashboard if dragged up enough
                        if value.translation.height < -dashboardThreshold || value.predictedEndTranslation.height < -dashboardThreshold * 1.5 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showDashboard = false
                                hideTabBar = false // Show tab bar when dashboard closes
                            }
                        }
                    }
                    dragOffset = 0
                }
        )
    }
}

struct PullIndicator: View {
    @State private var bounce = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
            
            Text("Pull for widgets")
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3))
        }
        .offset(y: bounce ? 5 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bounce = true
            }
        }
    }
}

struct DashboardSheet: View {
    @Binding var isPresented: Bool
    @Binding var hideTabBar: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle - tap or drag down to close
            VStack(spacing: 6) {
                // Drag handle
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                // Close hint text
                Text("Drag down to close")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3))
                    .padding(.top, 4)
                
                // REMOVED: X button - Settings button will be at bottom instead
                    Spacer()
                    .frame(height: 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)
            .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                        if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                        if value.translation.height > 80 || value.velocity.height > 500 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                                hideTabBar = false // Show tab bar when dashboard closes
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
            
            // Dashboard content
            DashboardView()
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(colorScheme == .dark 
                    ? Color(red: 0.12, green: 0.13, blue: 0.15) // Consistent dark gray
                    : Color(red: 0.95, green: 0.95, blue: 0.97) // Consistent light gray
                )
                .shadow(color: Color.black.opacity(0.3), radius: 30, y: 15)
        )
        .padding(.horizontal, 8)
        .padding(.top, 50)
        .offset(y: dragOffset)
    }
}

#Preview {
    MainView()
        .environmentObject(ActivityStore())
        .environmentObject(UserManager())
        .environmentObject(CalendarStore())
        .environmentObject(TodoStore())
}
