//
//  TimerView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI
import CoreMotion
import Combine
import MediaPlayer

enum TimerState: Equatable {
    case idle
    case running
    case onBreak
}

struct TimerView: View {
    @EnvironmentObject var activityStore: ActivityStore
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var timerStateStore: TimerStateStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    @StateObject private var musicPlayer = MusicPlayerManager()
    @StateObject private var streakManager = StreakManager.shared
    
    // Binding to hide tab bar when streak popup is shown
    @Binding var hideTabBarForStreak: Bool
    
    init(hideTabBarForStreak: Binding<Bool> = .constant(false)) {
        _hideTabBarForStreak = hideTabBarForStreak
    }
    
    // Live Activity and Dynamic Notch
    @State private var liveActivityManager: LiveActivityManager? = {
        if #available(iOS 16.1, *) {
            return LiveActivityManager.shared
        }
        return nil
    }()
    @State private var showDynamicNotch = false
    @State private var currentActivityName = "Focus Session"
    @State private var currentEmoji = "🎯"
    
    @State private var showMusicPlayer = false
    @State private var showPlaylistPicker = false
    @State private var currentPage: Int = 0 // 0 = timer, 1 = music
    
    // Preference key to communicate current page to MainView
    struct CurrentPageKey: PreferenceKey {
        static var defaultValue: Int = 0
        static func reduce(value: inout Int, nextValue: () -> Int) {
            value = nextValue()
        }
    }
    
    @State private var timerState: TimerState = .idle
    @State private var elapsedTime: TimeInterval = 0
    @State private var breakTime: TimeInterval = 0
    @State private var sessionStartTime: Date?
    @State private var timer: Timer?
    
    @State private var showStopAlert = false
    @State private var showResetAlert = false
    @State private var showSavePopup = false
    @State private var showStreakPopup = false
    @State private var streakPopupData: (count: Int, header: String, subHeader: String)?
    @State private var activityName: String = ""
    @State private var selectedEmoji: String = "🎯"
    
    // Animation states
    @State private var buttonScale: CGFloat = 1.0
    @State private var duckBounce: CGFloat = 0
    
    // Parallax states
    @State private var parallaxOffset: CGSize = .zero
    @StateObject private var motionManager = MotionManager()
    
    // Temporary storage for saving
    @State private var pendingStartTime: Date?
    @State private var pendingEndTime: Date?
    @State private var pendingDuration: TimeInterval = 0
    @State private var pendingBreakDuration: TimeInterval = 0
    
    // Current duck image - computed based on state
    private var currentDuckImage: String {
        timerState == .onBreak ? "duck_resting" : "duck_happy"
    }
    
    var body: some View {
        ZStack {
            // Background - only for timer view
            backgroundGradient
                .ignoresSafeArea()
            
            // Decorative elements with parallax - only for timer view
            decorativeElements
            
            // Dynamic Notch (for iPhone 14 models without Dynamic Island)
            if showDynamicNotch && timerState != .idle {
                VStack {
                    DynamicNotchView(
                        elapsedTime: elapsedTime,
                        breakTime: breakTime,
                        timerState: timerState,
                        activityName: currentActivityName,
                        emoji: currentEmoji
                    )
                    .padding(.top, 8)
                    Spacer()
                }
                .zIndex(1000) // Always on top
            }
            
            // Horizontal scroll for timer and music
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // Timer View - Centered
                        timerContentView
                            .frame(width: UIScreen.main.bounds.width)
                            .clipped() // Prevent sticking out
                            .id(0)
                            .onAppear {
                                currentPage = 0
                            }
                        
                        // Music Player View - Scroll right to access
                        musicPlayerView
                            .frame(width: UIScreen.main.bounds.width)
                            .clipped() // Prevent sticking out
                            .id(1)
                            .onAppear {
                                currentPage = 1
                            }
                    }
                }
                .scrollTargetBehavior(.paging)
            }
            .onChange(of: currentPage) { _, newValue in
                // Update preference when page changes
            }
            .preference(key: CurrentPageKey.self, value: currentPage)
                
            // Custom Save Popup
            if showSavePopup {
                SaveActivityPopup(
                    activityName: $activityName,
                    selectedEmoji: $selectedEmoji,
                    onSave: saveSession,
                    onDismiss: {
                        showSavePopup = false
                        activityName = ""
                        selectedEmoji = "🎯"
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
            
            // Playlist Picker
            if showPlaylistPicker {
                PlaylistPickerView(
                    playlists: musicPlayer.playlists,
                    onSelect: { playlist in
                        musicPlayer.playPlaylist(playlist, shuffle: true)
                        showPlaylistPicker = false
                    },
                    onDismiss: { showPlaylistPicker = false }
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            // Streak Popup - Full Screen
            if showStreakPopup, let streakData = streakPopupData {
                StreakPopupView(
                    streakCount: streakData.count,
                    header: streakData.header,
                    subHeader: streakData.subHeader,
                    onDismiss: {
                        withAnimation {
                            showStreakPopup = false
                            streakPopupData = nil
                            hideTabBarForStreak = false // Show tab bar again
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .zIndex(1000)
            }
        }
        .onChange(of: showStreakPopup) { _, isShowing in
            // Hide/show tab bar when streak popup appears/disappears
            hideTabBarForStreak = isShowing
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: timerState)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSavePopup)
        .alert("Stop Session?", isPresented: $showStopAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Stop", role: .destructive) {
                prepareToSaveSession()
            }
        } message: {
            Text("Are you sure you want to stop? Your activity will be saved.")
        }
        .alert("Reset Timer?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetSession()
            }
        } message: {
            Text("Are you sure you want to reset? This activity will be deleted.")
        }
        .onAppear {
            startDuckBounceAnimation()
            motionManager.startMotionUpdates()
            restoreTimerState()
        }
        .onDisappear {
            motionManager.stopMotionUpdates()
            saveCurrentState()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background || newPhase == .inactive {
                saveCurrentState()
            } else if newPhase == .active && oldPhase == .background {
                restoreTimerState()
            }
        }
        .onChange(of: motionManager.pitch) { _, _ in
            updateParallax()
        }
        .onChange(of: motionManager.roll) { _, _ in
            updateParallax()
        }
        .onChange(of: timerState) { _, _ in
            saveCurrentState()
            }
        .onChange(of: elapsedTime) { _, _ in
            // Save state periodically while running
            if timerState == .running || timerState == .onBreak {
                saveCurrentState()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BreakSessionFromLiveActivity"))) { _ in
            if timerState == .running {
                toggleBreak()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("BreakSessionFromDynamicNotch"))) { _ in
            if timerState == .running {
                toggleBreak()
        }
    }
    }
    
    private func saveCurrentState() {
        timerStateStore.saveState(
            timerState: timerState,
            elapsedTime: elapsedTime,
            breakTime: breakTime,
            sessionStartTime: sessionStartTime
        )
        }
    
    private func restoreTimerState() {
        guard let restored = timerStateStore.restoreTimerState() else { return }
        
        let (restoredState, restoredElapsed, restoredBreak, restoredStartTime) = restored
        
        // Only restore if we were in a running state
        if restoredState != .idle {
            timerState = restoredState
            elapsedTime = restoredElapsed
            breakTime = restoredBreak
            sessionStartTime = restoredStartTime
            
            // Restart timer if needed
            if timerState == .running {
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    elapsedTime += 1
                }
            } else if timerState == .onBreak {
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    breakTime += 1
                }
            }
        }
    }
    
    private func updateParallax() {
        withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.8)) {
            parallaxOffset = CGSize(
                width: motionManager.roll * 30,
                height: motionManager.pitch * 30
            )
        }
    }
    
    // MARK: - Greeting Header (Single Line with Interchangeable Messages)
    
    private var greetingHeader: some View {
        Text(greetingMessage)
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
        .padding(.horizontal, 20)
        .multilineTextAlignment(.center)
    }
    
    private var greetingMessage: String {
        let messages = [
            "Time To Focus, \(userManager.firstName).",
            "Time To Lock In, \(userManager.firstName).",
            "Time To Grind, \(userManager.firstName).",
            "Time To Hustle, \(userManager.firstName).",
            "Time To Crush It, \(userManager.firstName).",
            "Time To Level Up, \(userManager.firstName)."
        ]
        
        // Use activity count or random selection for variety
        let index = activityStore.activities.count % messages.count
        return messages[index]
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        Group {
            if timerState == .onBreak {
                LinearGradient(
                    colors: [
                        Color("BreakTop"),
                        Color("BreakBottom")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        Color("WorkTop"),
                        Color("WorkBottom")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .animation(.easeInOut(duration: 0.8), value: timerState)
    }
    
    private var decorativeElements: some View {
        GeometryReader { geometry in
            // Floating clouds with parallax effect
            ZStack {
                CloudShape()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 180, height: 90)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.15)
                    .offset(x: parallaxOffset.width * 1.5, y: parallaxOffset.height * 1.5)
                
                CloudShape()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 220, height: 110)
                    .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.1)
                    .offset(x: parallaxOffset.width * 2, y: parallaxOffset.height * 2)
                
                CloudShape()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 150, height: 75)
                    .position(x: geometry.size.width * 0.7, y: geometry.size.height * 0.3)
                    .offset(x: parallaxOffset.width * 1.2, y: parallaxOffset.height * 1.2)
                
                CloudShape()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 200, height: 100)
                    .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.45)
                    .offset(x: parallaxOffset.width * 1.8, y: parallaxOffset.height * 1.8)
                
                CloudShape()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 160, height: 80)
                    .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.55)
                    .offset(x: parallaxOffset.width * 1.3, y: parallaxOffset.height * 1.3)
            }
        }
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        VStack(spacing: 8) {
            // REMOVED: "Focus Time" / "Break Time" text
            
            Text(formattedTime)
                .font(.system(size: 72, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: timerState == .onBreak
                            ? [Color("BreakAccent1"), Color("BreakAccent2")]
                            : [Color("DuckYellow"), Color("DuckOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal)
    }
    
    private var formattedTime: String {
        let time = timerState == .onBreak ? breakTime : elapsedTime
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Timer Content View (Centered between tab bar and top)
    
    private var timerContentView: some View {
        GeometryReader { geometry in
            let availableHeight = geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom - 120 // Tab bar space
            let topSpacing = max(10, (availableHeight - 400) / 2) // SHIFTED UP EVEN MORE - reduced from 20 to 10
            
            VStack(spacing: 0) {
                // Top spacing - SHIFTED UP SIGNIFICANTLY MORE
                Spacer()
                    .frame(height: topSpacing + geometry.safeAreaInsets.top - 60) // Reduced by 60 more pixels
                
                // Greeting header (only when idle) - SINGLE LINE
                if timerState == .idle && !userManager.userName.isEmpty {
                    greetingHeader
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .padding(.bottom, 15) // Reduced padding
                }
                
                // Timer display - Centered
                timerDisplay
                    .padding(.bottom, 25) // Reduced padding
                
                // Duck image with floating animation
                duckImage
                    .padding(.bottom, 25) // Reduced padding
                
                // Control buttons
                controlButtons
                
                // Bottom spacing - ensure above tab bar
                Spacer()
                    .frame(height: max(140, topSpacing + geometry.safeAreaInsets.bottom + 80)) // Increased to ensure above tab bar
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Duck Image with Floating Animation
    
    private var duckImage: some View {
        ZStack {
            // Shadow
            Ellipse()
                .fill(Color.black.opacity(0.1))
                .frame(width: 180, height: 40)
                .offset(y: 120)
                .scaleEffect(timerState == .running ? 0.9 : 1.0)
            
            // Duck with gentle floating animation
            Image(currentDuckImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: UIScreen.main.bounds.height * 0.30)
                .offset(y: duckBounce)
                .id(currentDuckImage) // Force view recreation
        }
    }
    
    private func startDuckBounceAnimation() {
        // Gentle floating animation - always active
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            duckBounce = -12
        }
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        VStack(spacing: 20) {
            if timerState == .idle {
                // Start button
                Button(action: startTimer) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        Text("Start Focus")
                            .font(.system(.title2, design: .rounded, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .frame(width: 220, height: 60)
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
                    .shadow(color: Color("DuckOrange").opacity(0.4), radius: 15, y: 8)
                }
                .scaleEffect(buttonScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        buttonScale = 1.05
                    }
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                // Three control buttons
                HStack(spacing: 16) {
                    // Stop button
                    Button(action: { showStopAlert = true }) {
                        VStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                            Text("Stop")
                                .font(.system(.caption, design: .rounded, weight: .regular))
                        }
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.8))
                        )
                        .shadow(color: Color.red.opacity(0.3), radius: 10, y: 5)
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    // Break/Resume button
                    Button(action: toggleBreak) {
                        VStack(spacing: 6) {
                            Image(systemName: timerState == .onBreak ? "play.fill" : "cup.and.saucer.fill")
                                .font(.title2)
                            Text(timerState == .onBreak ? "Resume" : "Break")
                                .font(.system(.caption, design: .rounded, weight: .regular))
                        }
                        .foregroundColor(.white)
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: timerState == .onBreak
                                            ? [Color("DuckYellow"), Color("DuckOrange")]
                                            : [Color("BreakAccent1"), Color("BreakAccent2")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: (timerState == .onBreak ? Color("DuckOrange") : Color("BreakAccent1")).opacity(0.4), radius: 12, y: 6)
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    // Reset button
                    Button(action: { showResetAlert = true }) {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                            Text("Reset")
                                .font(.system(.caption, design: .rounded, weight: .regular))
                        }
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.6))
                        )
                        .shadow(color: Color.gray.opacity(0.3), radius: 10, y: 5)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.5).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: timerState)
    }
    
    // MARK: - Timer Functions
    
    private func startTimer() {
        timerState = .running
        sessionStartTime = Date()
        elapsedTime = 0
        breakTime = 0
        
        withAnimation(.spring(response: 0.3)) {
            buttonScale = 1.0
        }
        
        // Start Live Activity - Must be on main thread
        if #available(iOS 16.1, *) {
            DispatchQueue.main.async {
                if let manager = self.liveActivityManager {
                    print("🟢 Starting Live Activity from TimerView...")
                    manager.startActivity(
                        activityName: self.currentActivityName,
                        emoji: self.currentEmoji,
                        elapsedTime: self.elapsedTime,
                        breakTime: self.breakTime,
                        timerState: self.timerState,
                        startTime: self.sessionStartTime ?? Date()
                    )
                } else {
                    print("❌ LiveActivityManager is nil")
                }
            }
        }
        
        // Show Dynamic Notch for devices without Dynamic Island
        if !hasDynamicIsland() {
            showDynamicNotch = true
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
            
            // Update Live Activity
            if #available(iOS 16.1, *), let manager = liveActivityManager {
                manager.updateActivity(
                    elapsedTime: elapsedTime,
                    breakTime: breakTime,
                    timerState: timerState
                )
            }
        }
    }
    
    private func toggleBreak() {
        timer?.invalidate()
        timer = nil
        
        if timerState == .onBreak {
            // Resume work
            timerState = .running
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                elapsedTime += 1
                
                // Update Live Activity
                if #available(iOS 16.1, *), let manager = liveActivityManager {
                    manager.updateActivity(
                        elapsedTime: elapsedTime,
                        breakTime: breakTime,
                        timerState: timerState
                    )
                }
            }
        } else {
            // Start break
            timerState = .onBreak
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                breakTime += 1
                
                // Update Live Activity
                if #available(iOS 16.1, *), let manager = liveActivityManager {
                    manager.updateActivity(
                        elapsedTime: elapsedTime,
                        breakTime: breakTime,
                        timerState: timerState
                    )
                }
            }
        }
        
        // Update Live Activity immediately
        if #available(iOS 16.1, *), let manager = liveActivityManager {
            manager.updateActivity(
                elapsedTime: elapsedTime,
                breakTime: breakTime,
                timerState: timerState
            )
        }
    }
    
    private func prepareToSaveSession() {
        timer?.invalidate()
        timer = nil
        
        // End Live Activity
        if #available(iOS 16.1, *), let manager = liveActivityManager {
            manager.endActivity()
        }
        
        // Hide Dynamic Notch
        showDynamicNotch = false
        
        // Store pending values
        pendingStartTime = sessionStartTime
        pendingEndTime = Date()
        pendingDuration = elapsedTime
        pendingBreakDuration = breakTime
        
        // Reset UI
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            timerState = .idle
            elapsedTime = 0
            breakTime = 0
            sessionStartTime = nil
        }
        
        // Clear activity name and show custom popup
        activityName = ""
        selectedEmoji = "🎯"
        showSavePopup = true
    }
    
    private func saveSession() {
        var savedActivity: Activity?
        
        if let startTime = pendingStartTime {
            let finalName = activityName.trimmingCharacters(in: .whitespaces).isEmpty ? "Focus Session" : activityName
            let activity = Activity(
                name: finalName,
                emoji: selectedEmoji,
                startTime: startTime,
                endTime: pendingEndTime,
                duration: pendingDuration,
                breakDuration: pendingBreakDuration
            )
            activityStore.addActivity(activity)
            savedActivity = activity
            
            // Check for streak (15+ minutes of focus)
            if streakManager.updateStreak(for: activity) {
                let messages = streakManager.getStreakMessage(streakCount: streakManager.currentStreak)
                streakPopupData = (streakManager.currentStreak, messages.header, messages.subHeader)
                // Show streak popup after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showStreakPopup = true
                    }
                }
            }
        }
        
        // Clear pending values
        pendingStartTime = nil
        pendingEndTime = nil
        pendingDuration = 0
        pendingBreakDuration = 0
        activityName = ""
        selectedEmoji = "🎯"
        showSavePopup = false
        
        // Clear saved timer state
        timerStateStore.clearState()
        
        // Restart button pulse
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            buttonScale = 1.05
        }
    }
    
    private func resetSession() {
        timer?.invalidate()
        timer = nil
        
        // End Live Activity
        if #available(iOS 16.1, *), let manager = liveActivityManager {
            manager.endActivity()
        }
        
        // Hide Dynamic Notch
        showDynamicNotch = false
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            timerState = .idle
            elapsedTime = 0
            breakTime = 0
            sessionStartTime = nil
        }
        
        // Clear saved timer state
        timerStateStore.clearState()
        
        // Restart button pulse
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            buttonScale = 1.05
        }
    }
    
    // MARK: - Helper Functions
    
    private func hasDynamicIsland() -> Bool {
        // Check if device has Dynamic Island (iPhone 14 Pro and later)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.screen.bounds.width >= 393 // iPhone 14 Pro width
        }
        return false
    }
    
    // MARK: - Music Player View (Scroll Right)
    
    private var musicPlayerView: some View {
        ZStack {
            // Simple gray background - no clouds
            (colorScheme == .dark 
                ? Color(red: 0.12, green: 0.13, blue: 0.15)
                : Color(red: 0.95, green: 0.95, blue: 0.97))
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 20) // SHIFTED UP from 40 to 20
                    
                    // REMOVED: Header with duck icon and "Music" text
                    
                    // Now Playing Card - Centered and properly sized
                    if let nowPlaying = musicPlayer.nowPlaying {
                        nowPlayingCard(nowPlaying: nowPlaying)
                            .padding(.horizontal, 24)
                    } else {
                        noMusicView
                            .padding(.horizontal, 24)
                    }
                    
                    // Playlists Section
                    playlistsSection
                        .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .onAppear {
            Task {
                _ = await musicPlayer.requestAuthorization()
                musicPlayer.loadPlaylists()
                // Reload music state when view appears
                musicPlayer.nowPlaying = musicPlayer.musicPlayer.nowPlayingItem
                musicPlayer.isPlaying = musicPlayer.musicPlayer.playbackState == .playing
                musicPlayer.playbackTime = musicPlayer.musicPlayer.currentPlaybackTime
                musicPlayer.duration = musicPlayer.nowPlaying?.playbackDuration ?? 0
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && oldPhase == .background {
                // Reload music state when app becomes active
                musicPlayer.nowPlaying = musicPlayer.musicPlayer.nowPlayingItem
                musicPlayer.isPlaying = musicPlayer.musicPlayer.playbackState == .playing
                musicPlayer.playbackTime = musicPlayer.musicPlayer.currentPlaybackTime
                musicPlayer.duration = musicPlayer.nowPlaying?.playbackDuration ?? 0
            }
        }
    }
    
    // MARK: - Now Playing Card
    
    @State private var showConfetti = false
    @State private var isFavorited = false
    
    private func nowPlayingCard(nowPlaying: MPMediaItem) -> some View {
        VStack(spacing: 20) {
            // Album Art with Text Embedded - Apple Music Style
            Group {
                if let artwork = nowPlaying.artwork {
                    ZStack(alignment: .bottomLeading) {
                        // Album Art
                        Image(uiImage: artwork.image(at: CGSize(width: 400, height: 400)) ?? UIImage())
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: min(320, UIScreen.main.bounds.width - 60), height: min(320, UIScreen.main.bounds.width - 60))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        // Gradient overlay at bottom for text readability
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: min(320, UIScreen.main.bounds.width - 60) * 0.5)
                        .clipShape(
                            UnevenRoundedRectangle(
                                cornerRadii: .init(
                                    bottomLeading: 20,
                                    bottomTrailing: 20
                                )
                            )
                        )
                        
                        // Song Info overlaid on bottom with gradient
                        VStack(alignment: .leading, spacing: 4) {
                            Text(nowPlaying.title ?? "Unknown")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            Text(nowPlaying.artist ?? "Unknown Artist")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.4), radius: 20, y: 10)
                } else {
                    // Fallback: Vinyl-style design
                    ZStack {
                        // Vinyl record background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.15, green: 0.15, blue: 0.15),
                                        Color(red: 0.25, green: 0.25, blue: 0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: min(320, UIScreen.main.bounds.width - 60), height: min(320, UIScreen.main.bounds.width - 60))
                            .overlay(
                                // Vinyl grooves
                                ForEach(0..<8) { i in
                                    Circle()
                                        .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                        .frame(width: min(320, UIScreen.main.bounds.width - 60) - CGFloat(i * 20))
                                }
                            )
                            .overlay(
                                // Center hole
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 40, height: 40)
                            )
                        
                        // Duck icon in center
                        Image("duck_happy")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                        
                        // Text overlay at bottom
                        VStack(alignment: .leading, spacing: 4) {
                            Text(nowPlaying.title ?? "Unknown")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            Text(nowPlaying.artist ?? "Unknown Artist")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.black.opacity(0.6)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.4), radius: 20, y: 10)
                }
            }
            
            // Progress Bar with better scrubbing - SHORTENED for iPhone 14
            VStack(spacing: 10) {
                // Time labels above slider
                HStack {
                    Text(formatTime(musicPlayer.playbackTime))
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                        .monospacedDigit()
                    
                    Spacer()
                    
                    Text(formatTime(musicPlayer.duration))
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                        .monospacedDigit()
                }
                .padding(.horizontal, 40) // Wider padding to shorten effective width
                
                CustomSlider(
                    value: Binding(
                        get: { musicPlayer.playbackTime },
                        set: { newValue in
                            musicPlayer.seek(to: newValue)
                        }
                    ),
                    in: 0...max(musicPlayer.duration, 1),
                    onEditingChanged: { editing in
                        // Handle scrubbing
                    }
                )
                .frame(height: 44)
                .padding(.horizontal, 40) // Wider padding to shorten the bar for iPhone 14
            }
            
            // Control Buttons - RESIZED smaller
            HStack(spacing: 16) {
                // Shuffle
                Button(action: { musicPlayer.toggleShuffle() }) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18))
                        .foregroundColor(musicPlayer.isShuffling ? Color("DuckOrange") : (colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4)))
                }
                
                // Previous
                Button(action: { musicPlayer.skipToPrevious() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                }
                
                // Skip Back 15s
                Button(action: { musicPlayer.skipBackward(seconds: 15) }) {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 18))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                }
                
                // Play/Pause
                Button(action: { musicPlayer.togglePlayPause() }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("DuckYellow"), Color("DuckOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                // Skip Forward 15s
                Button(action: { musicPlayer.skipForward(seconds: 15) }) {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 18))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                }
                
                // Next
                Button(action: { musicPlayer.skipToNext() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                }
                
                // Repeat
                Button(action: { musicPlayer.toggleRepeat() }) {
                    Image(systemName: repeatIcon)
                        .font(.system(size: 18))
                        .foregroundColor(musicPlayer.repeatMode != .none ? Color("DuckOrange") : (colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4)))
                }
            }
            .padding(.horizontal, 20)
            
            // Favorite Button with Confetti
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isFavorited.toggle()
                    musicPlayer.toggleFavorite()
                }
                if isFavorited {
                    showConfetti = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showConfetti = false
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .foregroundColor(isFavorited ? .red : (colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4)))
                        .font(.title3)
                    Text(isFavorited ? "Favorited" : "Add to Favorites")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(isFavorited ? Color.red.opacity(0.1) : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05)))
                )
            }
            .overlay(
                // Confetti covers full screen, drops from top
                ConfettiView(isActive: $showConfetti)
                    .allowsHitTesting(false) // Don't block interactions
            )
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20) // Add horizontal padding to ensure it fits iPhone 14
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(colorScheme == .dark ? Color(red: 0.12, green: 0.13, blue: 0.15) : Color(red: 0.95, green: 0.95, blue: 0.97))
                .shadow(color: Color.black.opacity(0.15), radius: 25, y: 12)
        )
        .frame(maxWidth: UIScreen.main.bounds.width - 40) // Ensure it doesn't exceed screen width
        .onAppear {
            isFavorited = musicPlayer.isFavorited
        }
        .onChange(of: musicPlayer.isFavorited) { _, newValue in
            isFavorited = newValue
        }
    }
    
    // MARK: - No Music View
    
    private var noMusicView: some View {
        VStack(spacing: 20) {
            Image("duck_resting")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .opacity(0.6)
            
            Text("No music playing")
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
            
            Button(action: { showPlaylistPicker = true }) {
                HStack {
                    Image(systemName: "music.note.list")
                    Text("Choose Playlist")
                }
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
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
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.95))
        )
    }
    
    // MARK: - Playlists Section (Organized List)
    
    private var playlistsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Playlists")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                .padding(.horizontal, 4)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(musicPlayer.playlists, id: \.persistentID) { playlist in
                        PlaylistCard(playlist: playlist) {
                            musicPlayer.playPlaylist(playlist, shuffle: true)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var repeatIcon: String {
        switch musicPlayer.repeatMode {
        case .one:
            return "repeat.1"
        case .all:
            return "repeat"
        default:
            return "repeat"
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Motion Manager for Parallax

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            
            self?.pitch = motion.attitude.pitch
            self?.roll = motion.attitude.roll
        }
    }
    
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Save Activity Popup

struct SaveActivityPopup: View {
    @Binding var activityName: String
    @Binding var selectedEmoji: String
    let onSave: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var showEmojiPicker = false
    
    let commonEmojis = ["🎯", "📚", "💼", "💻", "✍️", "🧠", "📝", "🎨", "🏃", "🧘", "📖", "🔬", "🎵", "🌟", "⚡️", "🔥", "💪", "🚀", "✨", "🎮"]
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Popup card
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Save Activity")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                    
                    Text("Give your focus session a name")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                }
                
                // Emoji selector
                VStack(spacing: 12) {
                    Text("Choose an icon")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                    
                    Button(action: { showEmojiPicker.toggle() }) {
                        Text(selectedEmoji)
                            .font(.system(size: 50))
                            .frame(width: 80, height: 80)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color("DuckOrange").opacity(0.5), lineWidth: 2)
                            )
                    }
                    
                    if showEmojiPicker {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(commonEmojis, id: \.self) { emoji in
                                Button(action: {
                                    selectedEmoji = emoji
                                    showEmojiPicker = false
                                }) {
                                    Text(emoji)
                                        .font(.system(size: 28))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedEmoji == emoji
                                                    ? Color("DuckOrange").opacity(0.3)
                                                    : (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .animation(.spring(response: 0.3), value: showEmojiPicker)
                
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity name")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                    
                    TextField("e.g. Study Session", text: $activityName)
                        .font(.system(.body, design: .rounded))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("DuckOrange").opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Save button
                Button(action: onSave) {
                    Text("Save Activity")
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
                        .shadow(color: Color("DuckOrange").opacity(0.3), radius: 10, y: 5)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 30, y: 15)
            )
            .padding(.horizontal, 30)
        }
    }
}

// Custom cloud shape
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.2, y: height * 0.6))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.3),
            control: CGPoint(x: width * 0.1, y: height * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: width * 0.6, y: height * 0.25),
            control: CGPoint(x: width * 0.4, y: height * 0.1)
        )
        path.addQuadCurve(
            to: CGPoint(x: width * 0.85, y: height * 0.5),
            control: CGPoint(x: width * 0.9, y: height * 0.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: width * 0.7, y: height * 0.7),
            control: CGPoint(x: width * 0.95, y: height * 0.7)
        )
        path.addQuadCurve(
            to: CGPoint(x: width * 0.2, y: height * 0.6),
            control: CGPoint(x: width * 0.4, y: height * 0.9)
        )
        
        return path
    }
}

// MARK: - Custom Slider for Better Scrubbing

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let onEditingChanged: (Bool) -> Void
    
    @State private var isDragging = false
    @Environment(\.colorScheme) var colorScheme
    
    init(value: Binding<Double>, in range: ClosedRange<Double>, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self._value = value
        self.range = range
        self.onEditingChanged = onEditingChanged
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 3)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1))
                    .frame(height: 6)
                
                // Progress
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color("DuckYellow"), Color("DuckOrange")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width, height: 6)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                    .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - 10)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged(true)
                        }
                        let newValue = range.lowerBound + Double(gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound)
                        value = min(max(newValue, range.lowerBound), range.upperBound)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged(false)
                    }
            )
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var confettiParticles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiParticles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    createConfetti(screenWidth: geometry.size.width, screenHeight: geometry.size.height)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func createConfetti(screenWidth: CGFloat, screenHeight: CGFloat) {
        // Create confetti starting from top of screen, spread across width
        confettiParticles = (0..<50).map { _ in
            ConfettiParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth), // Spread across full width
                    y: -20 // Start above screen
                ),
                color: [Color.red, Color.orange, Color.yellow, Color.pink, Color.purple, Color.blue, Color.green].randomElement() ?? .red,
                size: CGFloat.random(in: 8...14),
                opacity: 1.0,
                velocity: CGPoint(
                    x: CGFloat.random(in: -50...50), // Horizontal drift
                    y: CGFloat.random(in: 200...400) // Falling speed
                )
            )
        }
        
        // Animate confetti falling from top to bottom
        withAnimation(.easeOut(duration: 2.0)) {
            for i in confettiParticles.indices {
                confettiParticles[i].position.y = screenHeight + 100 // Fall to bottom
                confettiParticles[i].position.x += confettiParticles[i].velocity.x * 2 // Add horizontal drift
                confettiParticles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    var velocity: CGPoint = CGPoint(x: 0, y: 0)
}

    // MARK: - Playlist Card (Organized List Style)

struct PlaylistCard: View {
    let playlist: MPMediaPlaylist
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Playlist artwork or icon
                if let artwork = playlist.items.first?.artwork, let image = artwork.image(at: CGSize(width: 60, height: 60)) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // Fallback: Music note icon
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color("DuckYellow").opacity(0.3), Color("DuckOrange").opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.title2)
                                .foregroundColor(Color("DuckOrange"))
                        )
                }
                
                // Playlist Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name ?? "Unknown Playlist")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        .lineLimit(1)
                    
                    Text("\(playlist.items.count) songs")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.2))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Playlist Picker View

struct PlaylistPickerView: View {
    let playlists: [MPMediaPlaylist]
    let onSelect: (MPMediaPlaylist) -> Void
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Choose Playlist")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4))
                    }
                }
                .padding()
                
                Divider()
                
                // Playlists
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(playlists, id: \.persistentID) { playlist in
                            Button(action: {
                                onSelect(playlist)
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "music.note.list")
                                        .font(.title2)
                                        .foregroundColor(Color("DuckOrange"))
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(playlist.name ?? "Unknown Playlist")
                                            .font(.system(.body, design: .rounded, weight: .semibold))
                                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                        
                                        Text("\(playlist.items.count) songs")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.2))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 30, y: 15)
            )
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    TimerView()
        .environmentObject(ActivityStore())
        .environmentObject(UserManager())
}
