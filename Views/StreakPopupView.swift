//
//  StreakPopupView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

struct StreakPopupView: View {
    let streakCount: Int
    let header: String
    let subHeader: String
    let onDismiss: () -> Void
    
    @State private var sliderOffset: CGFloat = 0
    @State private var isUnlocked = false
    @State private var fireScale: CGFloat = 0.5
    @State private var fireRotation: Double = 0
    @State private var confettiActive = false
    @Environment(\.colorScheme) var colorScheme
    
    private let sliderWidth: CGFloat = 280
    private let unlockThreshold: CGFloat = 200
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            // Confetti animation
            if confettiActive {
                ConfettiView(isActive: $confettiActive)
                    .allowsHitTesting(false)
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Fire icon with animation
                Image("fire_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(fireScale)
                    .rotationEffect(.degrees(fireRotation))
                    .shadow(color: Color.orange.opacity(0.6), radius: 20, x: 0, y: 0)
                    .onAppear {
                        // Complex fire animation
                        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                            fireScale = 1.1
                        }
                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                            fireRotation = 360
                        }
                        // Start confetti
                        confettiActive = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            confettiActive = false
                        }
                    }
                
                // Header - Motivational quote
                Text(header)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Sub header - Streak message
                Text(subHeader)
                    .font(.system(.headline, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Call slider button
                VStack(spacing: 16) {
                    Text("I'm committed")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundColor(.white)
                    
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: sliderWidth, height: 60)
                        
                        // Slider thumb
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [Color("DuckYellow"), Color("DuckOrange")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: isUnlocked ? "checkmark" : "arrow.right")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: sliderOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newOffset = min(max(0, value.translation.width), sliderWidth - 60)
                                    sliderOffset = newOffset
                                    
                                    if sliderOffset >= unlockThreshold && !isUnlocked {
                                        isUnlocked = true
                                        // Haptic feedback
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                    }
                                }
                                .onEnded { value in
                                    if isUnlocked {
                                        // Animate slide to end
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            sliderOffset = sliderWidth - 60
                                        }
                                        
                                        // Dismiss after animation
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            onDismiss()
                                        }
                                    } else {
                                        // Spring back
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            sliderOffset = 0
                                        }
                                    }
                                }
                        )
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    StreakPopupView(
        streakCount: 5,
        header: "You're on fire! 🔥",
        subHeader: "Welcome, 5 day streak!",
        onDismiss: {}
    )
}

