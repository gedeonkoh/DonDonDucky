//
//  OnboardingView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI
import AuthenticationServices
import PhotosUI

enum OnboardingStep {
    case welcome
    case signIn
    case nameEntry
    case profilePicture
}

struct OnboardingView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var enteredName: String = ""
    @State private var duckOffset: CGFloat = 0
    @State private var showContent = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showNameError = false
    
    var isNameValid: Bool {
        enteredName.trimmingCharacters(in: .whitespaces).count >= 3
    }
    
    var body: some View {
        ZStack {
            // Background
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
                    Ellipse()
                        .fill(Color.black.opacity(0.1))
                        .frame(width: 100, height: 25)
                        .offset(y: 70)
                    
                    Image("duck_happy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                        .offset(y: duckOffset)
                }
                
                // Content based on step
                Group {
                    switch currentStep {
                    case .welcome:
                        welcomeContent
                    case .signIn:
                        signInContent
                    case .nameEntry:
                        nameEntryContent
                    case .profilePicture:
                        profilePictureContent
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 30)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Welcome Content
    
    private var welcomeContent: some View {
        VStack(spacing: 20) {
            Text("Welcome to\nQuack Time!")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("DuckYellow"), Color("DuckOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Your adorable focus companion")
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
                .frame(height: 40)
            
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showContent = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentStep = .signIn
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showContent = true
                    }
                }
            }) {
                Text("Get Started")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 220, height: 56)
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
        }
    }
    
    // MARK: - Sign In Content
    
    private var signInContent: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("DuckYellow"), Color("DuckOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Sign in to sync your focus sessions")
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Spacer()
                .frame(height: 30)
            
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                userManager.handleSignInWithApple(result: result)
                
                // If name wasn't provided, go to name entry
                if userManager.userName.isEmpty {
                    transitionTo(.nameEntry)
                } else {
                    transitionTo(.profilePicture)
                }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(width: 280, height: 50)
            .cornerRadius(25)
            
            Button(action: {
                transitionTo(.nameEntry)
            }) {
                Text("Skip for now")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 10)
        }
    }
    
    // MARK: - Name Entry Content
    
    private var nameEntryContent: some View {
        VStack(spacing: 20) {
            Text("What's your name?")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("DuckYellow"), Color("DuckOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("So we can personalize your experience")
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
                .frame(height: 20)
            
            VStack(spacing: 8) {
                TextField("", text: $enteredName, prompt: Text("Enter your name").foregroundColor(.white.opacity(0.5)))
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(showNameError ? Color.red.opacity(0.6) : Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .frame(width: 280)
                    .onChange(of: enteredName) { _, _ in
                        showNameError = false
                    }
                
                // Character count hint
                Text("At least 3 characters")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(showNameError ? .red.opacity(0.8) : .white.opacity(0.5))
            }
            
            Spacer()
                .frame(height: 20)
            
            Button(action: {
                if isNameValid {
                    userManager.saveUserName(enteredName.trimmingCharacters(in: .whitespaces))
                    transitionTo(.profilePicture)
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        showNameError = true
                    }
                }
            }) {
                Text("Continue")
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(width: 220, height: 56)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isNameValid
                                        ? [Color("DuckYellow"), Color("DuckOrange")]
                                        : [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: isNameValid ? Color("DuckOrange").opacity(0.4) : Color.clear, radius: 15, y: 8)
            }
        }
    }
    
    // MARK: - Profile Picture Content
    
    private var profilePictureContent: some View {
        VStack(spacing: 20) {
            Text("Add a profile picture")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("DuckYellow"), Color("DuckOrange")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Make your Duck ID unique")
                .font(.system(.body, design: .rounded, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
                .frame(height: 20)
            
            // Profile picture preview
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                if let profileImage = userManager.profileImage {
                    profileImage
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Image("duck_happy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
            )
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Text("Upload image")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(Color("DuckOrange"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        userManager.saveProfileImage(data)
                    }
                }
            }
            
            Spacer()
                .frame(height: 20)
            
            VStack(spacing: 12) {
                Button(action: {
                    userManager.completeOnboarding()
                }) {
                    Text("Continue")
                        .font(.system(.title3, design: .rounded, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(width: 220, height: 56)
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
                
                Button(action: {
                    userManager.completeOnboarding()
                }) {
                    Text("Skip")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private func transitionTo(_ step: OnboardingStep) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentStep = step
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
    
    private func startAnimations() {
        // Duck bobbing
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            duckOffset = -10
        }
        
        // Content fade in
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            showContent = true
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserManager())
}
