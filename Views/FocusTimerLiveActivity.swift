//
//  FocusTimerLiveActivity.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI
import WidgetKit
import ActivityKit
import AppIntents

@available(iOS 16.1, *)
struct FocusTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusTimerActivityAttributes.self) { context in
            // Lock screen/banner UI - Enhanced for better visibility
            HStack(spacing: 16) {
                // Left side - Duck icon
                Image("duck_resting")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .padding(.leading, 4)
                
                // Timer in middle - More prominent
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.activityName)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(context.state.formattedTime)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundColor(context.state.timerState == "onBreak" ? .blue : .orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right side - Break button
                Button(intent: BreakSessionIntent()) {
                    VStack(spacing: 4) {
                        Image(systemName: "pause.circle.fill")
                            .font(.title2)
                        Text("Break")
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                    }
                    .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                context.state.timerState == "onBreak" ? .blue.opacity(0.3) : .orange.opacity(0.3),
                                context.state.timerState == "onBreak" ? .blue.opacity(0.1) : .orange.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image("duck_resting")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.activityName)
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Text(context.state.formattedTime)
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .monospacedDigit()
                                .foregroundColor(context.state.timerState == "onBreak" ? .blue : .orange)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Button(intent: BreakSessionIntent()) {
                        Image(systemName: "pause.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Additional info if needed
                    HStack {
                        Text("Focus Time")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(context.state.elapsedTime / 60))m")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                // Compact leading
                Image("duck_resting")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            } compactTrailing: {
                // Compact trailing - timer
                Text(context.state.formattedTime)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundColor(context.state.timerState == "onBreak" ? .blue : .orange)
            } minimal: {
                // Minimal - just duck icon
                Image("duck_resting")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
        }
    }
}

// App Intent for break session button
@available(iOS 16.0, *)
struct BreakSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Break Session"
    
    func perform() async throws -> some IntentResult {
        // This will be handled by the app
        NotificationCenter.default.post(name: NSNotification.Name("BreakSessionFromLiveActivity"), object: nil)
        return .result()
    }
}

