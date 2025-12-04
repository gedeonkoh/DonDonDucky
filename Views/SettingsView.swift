//
//  SettingsView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI
import PhotosUI
import AuthenticationServices

struct SettingsView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var calendarStore: CalendarStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var editedName: String = ""
    @State private var showIDEditor = false
    @State private var showImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
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
                        // Profile Section
                        profileSection
                        
                        // Appearance Section
                        appearanceSection
                        
                        // Calendar Sync Section
                        calendarSyncSection
                        
                        // ID Card Section
                        idCardSection
                        
                        // Account Section
                        accountSection
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
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
            .onAppear {
                editedName = userManager.userName
            }
            .sheet(isPresented: $showIDEditor) {
                IDEditorView()
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Profile")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                Spacer()
            }
            
            VStack(spacing: 0) {
                // Profile Picture
                HStack {
                    Text("Profile picture")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                    
                    Spacer()
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let profileImage = userManager.profileImage {
                            profileImage
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color("DuckYellow").opacity(0.3))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image("duck_happy")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 30, height: 30)
                                )
                        }
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                userManager.saveProfileImage(data)
                            }
                        }
                    }
                }
                .padding()
                
                Divider()
                    .padding(.leading)
                
                // Name
                HStack {
                    Text("Name")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                    
                    Spacer()
                    
                    TextField("Your name", text: $editedName)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                        .multilineTextAlignment(.trailing)
                        .onChange(of: editedName) { _, newValue in
                            if newValue.trimmingCharacters(in: .whitespaces).count >= 3 {
                                userManager.saveUserName(newValue.trimmingCharacters(in: .whitespaces))
                            }
                        }
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
            )
        }
    }
    
    // MARK: - Appearance Section
    
    private var appearanceSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Appearance")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                Spacer()
            }
            
            VStack(spacing: 0) {
                HStack {
                    Text("Dark mode")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                    
                    Spacer()
                    
                    Toggle("", isOn: $userManager.isDarkMode)
                        .tint(Color("DuckOrange"))
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
            )
        }
    }
    
    // MARK: - Calendar Sync Section
    
    private var calendarSyncSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Calendar")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                Spacer()
            }
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(Color("DuckOrange"))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Calendar Sync")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        
                        Text("Sync events to Apple Calendar")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { calendarStore.appleCalendarSyncEnabled },
                        set: { calendarStore.setAppleCalendarSync($0) }
                    ))
                    .tint(Color("DuckOrange"))
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
            )
        }
    }
    
    // MARK: - ID Card Section
    
    private var idCardSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Duck ID")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                Spacer()
            }
            
            Button(action: { showIDEditor = true }) {
                HStack {
                    // Mini ID preview
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color("DuckYellow").opacity(0.3), Color("DuckOrange").opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 32)
                        
                        Image("duck_happy")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Edit your Duck ID")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        
                        Text("Customize your student card")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.3))
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
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Account")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                Spacer()
            }
            
            VStack(spacing: 0) {
                if userManager.isSignedIn {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Signed in with Apple")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        
                        Spacer()
                    }
                    .padding()
                    
                    Divider()
                        .padding(.leading)
                    
                    // iCloud Sync Toggle
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(Color("DuckOrange"))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Sync")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                            
                            Text("Sync your data across devices")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { userManager.iCloudSyncEnabled },
                            set: { userManager.setiCloudSync($0) }
                        ))
                        .tint(Color("DuckOrange"))
                    }
                    .padding()
                    
                    Divider()
                        .padding(.leading)
                    
                    Button(action: {
                        userManager.signOut()
                    }) {
                        HStack {
                            Text("Sign out")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                            
                            Text("Not signed in")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            Spacer()
                        }
                        .padding()
                        
                        Divider()
                            .padding(.horizontal)
                        
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            userManager.handleSignInWithApple(result: result)
                            // Enable iCloud sync when signing in
                            userManager.enableiCloudSync()
                        }
                        .frame(height: 50)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
            )
        }
    }
}

// MARK: - ID Editor View

struct IDEditorView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var editedBirthday: Date = Date()
    @State private var editedSchool: String = ""
    @State private var editedYearLevel: String = ""
    @State private var selectedLogo: Int = 0
    @State private var selectedColor: Int = 0
    
    let logoNames = ["Quack Time", "Focus Duck", "Study Buddy"]
    let logoImageNames = ["logo_quacktime", "logo_focusduck", "logo_studybuddy"]
    let idCardColors: [Color] = [.orange, .blue, .green, .purple, .pink, .red, .teal, .indigo]
    let colorNames = ["Orange", "Blue", "Green", "Purple", "Pink", "Red", "Teal", "Indigo"]
    
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
                        // ID Card Preview
                        idCardPreview
                        
                        // Logo Selection
                        logoSection
                        
                        // Details Section
                        detailsSection
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Duck ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("DuckOrange"))
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(Color("DuckOrange"))
                }
            }
            .onAppear {
                editedBirthday = userManager.birthday
                editedSchool = userManager.school
                editedYearLevel = userManager.yearLevel
                selectedLogo = userManager.selectedLogoIndex
                selectedColor = userManager.idCardColorIndex
            }
        }
    }
    
    // MARK: - ID Card Preview
    
    private var idCardPreview: some View {
        VStack(spacing: 0) {
            // Card Header
            HStack {
                Image(logoImageNames[selectedLogo])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 20)
                
                Spacer()
                
                Image("duck_happy")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [
                        idCardColors[selectedColor].opacity(0.3),
                        idCardColors[selectedColor].opacity(0.15)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Dashed line
            Rectangle()
                .fill(idCardColors[selectedColor].opacity(0.3))
                .frame(height: 1)
            
            // Card Body
            HStack(spacing: 12) {
                // Profile Picture
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(idCardColors[selectedColor].opacity(0.5), lineWidth: 2)
                        .frame(width: 70, height: 85)
                    
                    if let profileImage = userManager.profileImage {
                        profileImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 66, height: 81)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image("duck_happy")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                }
                
                // Info
                VStack(alignment: .leading, spacing: 8) {
                    // Details grid
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("name")
                                .font(.system(size: 8, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                            Text(userManager.firstName.isEmpty ? "---" : userManager.firstName.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("birthday")
                                .font(.system(size: 8, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                            Text(formattedBirthday)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        }
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("school")
                                .font(.system(size: 8, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                            Text(editedSchool.isEmpty ? "---" : editedSchool.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("year level")
                                .font(.system(size: 8, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
                            Text(editedYearLevel.isEmpty ? "---" : editedYearLevel.uppercased())
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(idCardColors[selectedColor].opacity(0.3), lineWidth: 1)
        )
    }
    
    private var formattedBirthday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        return formatter.string(from: editedBirthday)
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Logo")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    Button(action: { selectedLogo = index }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
                                .frame(height: 50)
                            
                            Image(logoImageNames[index])
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 20)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedLogo == index ? Color("DuckOrange") : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Color Section
            HStack {
                Text("Card Color")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                Spacer()
            }
            .padding(.top, 8)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(0..<idCardColors.count, id: \.self) { index in
                    Button(action: { selectedColor = index }) {
                        Circle()
                            .fill(idCardColors[index])
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedColor == index ? 3 : 0)
                            )
                            .shadow(color: idCardColors[index].opacity(0.4), radius: selectedColor == index ? 5 : 0)
                    }
                }
            }
        }
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Details")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                Spacer()
            }
            
            VStack(spacing: 0) {
                // Birthday
                HStack {
                    Text("Birthday")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                    
                    Spacer()
                    
                    DatePicker("", selection: $editedBirthday, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                .padding()
                
                Divider()
                    .padding(.leading)
                
                // School
                HStack {
                    Text("School")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                    
                    Spacer()
                    
                    TextField("Your school", text: $editedSchool)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                        .multilineTextAlignment(.trailing)
                }
                .padding()
                
                Divider()
                    .padding(.leading)
                
                // Year Level
                HStack {
                    Text("Year level")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                    
                    Spacer()
                    
                    TextField("e.g. 3rd Year", text: $editedYearLevel)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                        .multilineTextAlignment(.trailing)
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.9))
            )
        }
    }
    
    private func saveChanges() {
        userManager.saveBirthday(editedBirthday)
        userManager.saveSchool(editedSchool)
        userManager.saveYearLevel(editedYearLevel)
        userManager.saveLogoIndex(selectedLogo)
        userManager.saveIdCardColor(selectedColor)
    }
}

#Preview {
    SettingsView()
        .environmentObject(UserManager())
}

