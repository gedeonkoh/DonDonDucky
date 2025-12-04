//
//  r1App.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI
import ActivityKit

@main
struct r1App: App {
    init() {
        // Verify Live Activity widget is available
        if #available(iOS 16.1, *) {
            print("📱 App initialized - Live Activities available")
            let authInfo = ActivityAuthorizationInfo()
            print("   - areActivitiesEnabled: \(authInfo.areActivitiesEnabled)")
        } else {
            print("⚠️ iOS version too old for Live Activities (requires 16.1+)")
        }
    }
    @StateObject private var activityStore = ActivityStore()
    @StateObject private var userManager = UserManager()
    @StateObject private var calendarStore = CalendarStore()
    @StateObject private var todoStore = TodoStore()
    @StateObject private var timerStateStore = TimerStateStore()
    @State private var showSplash = true
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content or onboarding
                Group {
                    if userManager.hasCompletedOnboarding {
                        ContentView()
                    } else {
                        OnboardingView()
                    }
                }
                .environmentObject(activityStore)
                .environmentObject(userManager)
                .environmentObject(calendarStore)
                .environmentObject(todoStore)
                .environmentObject(timerStateStore)
                .opacity(showSplash ? 0 : 1)
                
                // Splash screen
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                // Show splash for 5 seconds then fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
