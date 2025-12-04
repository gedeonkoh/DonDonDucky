//
//  SplashScreenView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var duckOffset: CGFloat = 0
    @State private var showText = false
    @State private var loadingProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color("SplashTop"),
                    Color("SplashBottom")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Floating bubbles
            BubblesView()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Duck mascot
                ZStack {
                    // Shadow
                    Ellipse()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 120, height: 30)
                        .offset(y: 80)
                        .scaleEffect(isAnimating ? 0.9 : 1.1)
                    
                    // Duck image
                    Image("duck_loading")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .offset(y: duckOffset)
                }
                
                // App title
                VStack(spacing: 8) {
                    Text("Quack Time")
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("DuckYellow"), Color("DuckOrange")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Your focus buddy")
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 20)
                
                Spacer()
                
                // Loading bar
                VStack(spacing: 12) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 200, height: 8)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color("DuckYellow"), Color("DuckOrange")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 200 * loadingProgress, height: 8)
                    }
                    
                    Text("Loading...")
                        .font(.system(.caption, design: .rounded, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Duck bobbing animation
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            duckOffset = -15
            isAnimating = true
        }
        
        // Text fade in
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            showText = true
        }
        
        // Loading progress - 5 seconds
        withAnimation(.easeInOut(duration: 4.5)) {
            loadingProgress = 1.0
        }
    }
}

// Floating bubbles background
struct BubblesView: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<8, id: \.self) { index in
                BubbleView(
                    size: CGFloat.random(in: 20...60),
                    xPosition: CGFloat.random(in: 0...geometry.size.width),
                    delay: Double(index) * 0.3
                )
            }
        }
    }
}

struct BubbleView: View {
    let size: CGFloat
    let xPosition: CGFloat
    let delay: Double
    
    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.1))
            .frame(width: size, height: size)
            .position(x: xPosition, y: UIScreen.main.bounds.height + 50)
            .offset(y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 3...5))
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    yOffset = -UIScreen.main.bounds.height - 100
                    opacity = 0.6
                }
            }
    }
}

#Preview {
    SplashScreenView()
}

