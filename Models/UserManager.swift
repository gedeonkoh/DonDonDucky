//
//  UserManager.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import SwiftUI
import AuthenticationServices
import Combine

class UserManager: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var userName: String = ""
    @Published var userID: String = ""
    @Published var hasCompletedOnboarding: Bool = false
    @Published var profileImageData: Data?
    @Published var birthday: Date = Date()
    @Published var school: String = ""
    @Published var yearLevel: String = ""
    @Published var selectedLogoIndex: Int = 0
    @Published var idCardColorIndex: Int = 0
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @AppStorage("iCloudSyncEnabled") var iCloudSyncEnabled: Bool = false
    
    private let userNameKey = "userName"
    private let userIDKey = "userID"
    private let onboardingKey = "hasCompletedOnboarding"
    private let profileImageKey = "profileImageData"
    private let birthdayKey = "userBirthday"
    private let schoolKey = "userSchool"
    private let yearLevelKey = "userYearLevel"
    private let logoIndexKey = "selectedLogoIndex"
    private let idCardColorKey = "idCardColorIndex"
    
    init() {
        loadUserData()
    }
    
    func loadUserData() {
        userName = UserDefaults.standard.string(forKey: userNameKey) ?? ""
        userID = UserDefaults.standard.string(forKey: userIDKey) ?? ""
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        isSignedIn = !userID.isEmpty
        profileImageData = UserDefaults.standard.data(forKey: profileImageKey)
        school = UserDefaults.standard.string(forKey: schoolKey) ?? ""
        yearLevel = UserDefaults.standard.string(forKey: yearLevelKey) ?? ""
        selectedLogoIndex = UserDefaults.standard.integer(forKey: logoIndexKey)
        idCardColorIndex = UserDefaults.standard.integer(forKey: idCardColorKey)
        
        if let birthdayData = UserDefaults.standard.object(forKey: birthdayKey) as? Date {
            birthday = birthdayData
        }
    }
    
    func saveUserName(_ name: String) {
        userName = name
        UserDefaults.standard.set(name, forKey: userNameKey)
    }
    
    func saveProfileImage(_ data: Data?) {
        profileImageData = data
        if let data = data {
            UserDefaults.standard.set(data, forKey: profileImageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: profileImageKey)
        }
    }
    
    func saveBirthday(_ date: Date) {
        birthday = date
        UserDefaults.standard.set(date, forKey: birthdayKey)
    }
    
    func saveSchool(_ school: String) {
        self.school = school
        UserDefaults.standard.set(school, forKey: schoolKey)
    }
    
    func saveYearLevel(_ level: String) {
        yearLevel = level
        UserDefaults.standard.set(level, forKey: yearLevelKey)
    }
    
    func saveLogoIndex(_ index: Int) {
        selectedLogoIndex = index
        UserDefaults.standard.set(index, forKey: logoIndexKey)
    }
    
    func saveIdCardColor(_ index: Int) {
        idCardColorIndex = index
        UserDefaults.standard.set(index, forKey: idCardColorKey)
    }
    
    func enableiCloudSync() {
        iCloudSyncEnabled = true
        // Sync data to iCloud
        syncToiCloud()
    }
    
    func setiCloudSync(_ enabled: Bool) {
        iCloudSyncEnabled = enabled
        if enabled {
            syncToiCloud()
        }
    }
    
    private func syncToiCloud() {
        // Use NSUbiquitousKeyValueStore for iCloud sync
        let store = NSUbiquitousKeyValueStore.default
        store.set(userName, forKey: userNameKey)
        store.set(userID, forKey: userIDKey)
        store.set(school, forKey: schoolKey)
        store.set(yearLevel, forKey: yearLevelKey)
        store.set(selectedLogoIndex, forKey: logoIndexKey)
        store.set(idCardColorIndex, forKey: idCardColorKey)
        store.synchronize()
    }
    
    func handleSignInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                userID = appleIDCredential.user
                UserDefaults.standard.set(userID, forKey: userIDKey)
                
                // Get full name if provided (only on first sign in)
                if let fullName = appleIDCredential.fullName {
                    let firstName = fullName.givenName ?? ""
                    let lastName = fullName.familyName ?? ""
                    let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        saveUserName(name)
                    }
                }
                
                isSignedIn = true
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }
    
    func signOut() {
        userID = ""
        userName = ""
        isSignedIn = false
        hasCompletedOnboarding = false
        profileImageData = nil
        school = ""
        yearLevel = ""
        selectedLogoIndex = 0
        idCardColorIndex = 0
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: onboardingKey)
        UserDefaults.standard.removeObject(forKey: profileImageKey)
        UserDefaults.standard.removeObject(forKey: schoolKey)
        UserDefaults.standard.removeObject(forKey: yearLevelKey)
        UserDefaults.standard.removeObject(forKey: logoIndexKey)
        UserDefaults.standard.removeObject(forKey: idCardColorKey)
    }
    
    // MARK: - Greeting Messages
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }
    
    var personalizedMessage: String {
        let firstName = userName.components(separatedBy: " ").first ?? userName
        let messages = [
            "Ready to get on the roll, \(firstName)?",
            "Let's crush it today, \(firstName)!",
            "Time to focus, \(firstName)!",
            "Let's make today count, \(firstName)!",
            "Ready to be productive, \(firstName)?",
            "Let's do this, \(firstName)!",
            "Focus mode activated, \(firstName)!",
            "You've got this, \(firstName)!",
            "Time to shine, \(firstName)!",
            "Let's get quacking, \(firstName)!"
        ]
        
        // Use a seeded random based on day so message stays consistent for the day
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % messages.count
        return messages[index]
    }
    
    var firstName: String {
        userName.components(separatedBy: " ").first ?? userName
    }
    
    var formattedBirthday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        return formatter.string(from: birthday)
    }
    
    var profileImage: Image? {
        guard let data = profileImageData,
              let uiImage = UIImage(data: data) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}
