//
//  DynamicNotchView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

struct DynamicNotchView: View {
    let elapsedTime: TimeInterval
    let breakTime: TimeInterval
    let timerState: TimerState
    let activityName: String
    let emoji: String
    
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    private var displayTime: TimeInterval {
        timerState == .onBreak ? breakTime : elapsedTime
    }
    
    private var formattedTime: String {
        let hours = Int(displayTime) / 3600
        let minutes = (Int(displayTime) % 3600) / 60
        let seconds = Int(displayTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Expanded view
                expandedView
                    .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                // Compact view (notch)
                compactView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        // Dragging up - expand
                        dragOffset = value.translation.height
                    } else if isExpanded && value.translation.height > 0 {
                        // Dragging down - collapse
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -30 {
                        isExpanded = true
                    } else if value.translation.height > 30 {
                        isExpanded = false
                    }
                    dragOffset = 0
                }
        )
    }
    
    // MARK: - Compact Notch View
    
    private var compactView: some View {
        HStack(spacing: 8) {
            // Duck icon
            Image("duck_resting")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            
            // Timer
            Text(formattedTime)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundColor(timerState == .onBreak ? Color("BreakAccent1") : Color("DuckOrange"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(colorScheme == .dark 
                    ? Color(red: 0.12, green: 0.13, blue: 0.15)
                    : Color.white
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
        )
        .onTapGesture {
            withAnimation {
                isExpanded = true
            }
        }
    }
    
    // MARK: - Expanded View
    
    private var expandedView: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                // Emoji and name
                HStack(spacing: 8) {
                    Text(emoji)
                        .font(.title2)
                    
                    Text(activityName)
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                }
                
                Spacer()
                
                // Close button
                Button(action: {
                    withAnimation {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4))
                }
            }
            
            // Timer display
            Text(formattedTime)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(
                    LinearGradient(
                        colors: timerState == .onBreak 
                            ? [Color("BreakAccent1"), Color("BreakAccent2")]
                            : [Color("DuckYellow"), Color("DuckOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Break button
            Button(action: {
                NotificationCenter.default.post(name: NSNotification.Name("BreakSessionFromDynamicNotch"), object: nil)
            }) {
                HStack {
                    Image(systemName: "pause.circle.fill")
                        .font(.title3)
                    Text("Break Session")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark 
                    ? Color(red: 0.12, green: 0.13, blue: 0.15)
                    : Color.white
                )
                .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
        )
        .padding(.horizontal, 20)
        .offset(y: dragOffset)
    }
}

#Preview {
    DynamicNotchView(
        elapsedTime: 1250,
        breakTime: 0,
        timerState: .running,
        activityName: "Focus Session",
        emoji: "🎯"
    )
    .padding(.top, 50)
}

