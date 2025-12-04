//
//  EditCountdownView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

struct EditCountdownView: View {
    @EnvironmentObject var calendarStore: CalendarStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let event: CalendarEvent
    
    @State private var title: String
    @State private var countdownDate: Date
    @State private var countdownTime: Date
    @State private var selectedEmoji: String
    @State private var showEmojiPicker = false
    @State private var notes: String
    @State private var notifyBefore: Int?
    @State private var showDeleteAlert = false
    
    let commonEmojis = ["🎯", "📚", "💼", "💻", "✍️", "🧠", "📝", "🎨", "🏃", "🧘", "📖", "🔬", "🎵", "🌟", "⚡️", "🔥", "💪", "🚀", "✨", "🎮", "📅", "⏰", "🎓", "🏆", "🎪"]
    
    init(event: CalendarEvent) {
        self.event = event
        _title = State(initialValue: event.title)
        _countdownDate = State(initialValue: event.startDate)
        _countdownTime = State(initialValue: event.startDate)
        _selectedEmoji = State(initialValue: event.emoji ?? "🎯")
        _notes = State(initialValue: event.notes)
        _notifyBefore = State(initialValue: event.notifyBefore)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color("WorkTop"), Color("WorkBottom")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Event Info Header
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Text(selectedEmoji)
                                    .font(.system(size: 40))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(title)
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                    
                                    Text(dateTimeString)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                                }
                                
                                Spacer()
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.9))
                        )
                        
                        // Time Until Display (Auto-calculated, updates as you edit)
                        VStack(spacing: 8) {
                            Text("Time Until Event")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            Text(timeUntilString)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color("DuckYellow"), Color("DuckOrange")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.9))
                                )
                        }
                        
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Name")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            TextField("e.g., Final Exam", text: $title)
                                .font(.system(.body, design: .rounded))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                                )
                        }
                        
                        // Emoji Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose an icon")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            Button(action: { showEmojiPicker.toggle() }) {
                                HStack {
                                    Text(selectedEmoji)
                                        .font(.system(size: 40))
                                    
                                    Spacer()
                                    
                                    Image(systemName: showEmojiPicker ? "chevron.up" : "chevron.down")
                                        .foregroundColor(Color("DuckOrange"))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
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
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .animation(.spring(response: 0.3), value: showEmojiPicker)
                        
                        // Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            DatePicker("", selection: $countdownDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                                )
                        }
                        
                        // Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Time")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            DatePicker("", selection: $countdownTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                                )
                        }
                        
                        // Notification Reminder
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Remind Me")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            Picker("", selection: $notifyBefore) {
                                Text("None").tag(nil as Int?)
                                Text("5 minutes before").tag(5 as Int?)
                                Text("15 minutes before").tag(15 as Int?)
                                Text("30 minutes before").tag(30 as Int?)
                                Text("1 hour before").tag(60 as Int?)
                                Text("1 day before").tag(1440 as Int?)
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                            )
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            TextField("Add notes...", text: $notes, axis: .vertical)
                                .font(.system(.body, design: .rounded))
                                .lineLimit(3...6)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                                )
                        }
                        
                        // Save Button
                        Button(action: updateCountdown) {
                            Text("Save Changes")
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
                        }
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.6 : 1)
                        
                        // Delete Button
                        Button(action: { showDeleteAlert = true }) {
                            Text("Delete Countdown")
                                .font(.system(.headline, design: .rounded, weight: .medium))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    Capsule()
                                        .stroke(Color.red, lineWidth: 2)
                                )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Countdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("DuckOrange"))
                }
            }
            .alert("Delete Countdown?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    calendarStore.deleteEvent(event)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this countdown?")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var dateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: eventDateTime)
    }
    
    private var eventDateTime: Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: calendar.component(.hour, from: countdownTime),
                           minute: calendar.component(.minute, from: countdownTime),
                           second: 0,
                           of: countdownDate) ?? countdownDate
    }
    
    private var timeUntilString: String {
        let interval = eventDateTime.timeIntervalSinceNow
        
        if interval <= 0 {
            return "Event has passed"
        }
        
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Actions
    
    private func updateCountdown() {
        let calendar = Calendar.current
        let eventDateTime = calendar.date(bySettingHour: calendar.component(.hour, from: countdownTime),
                                         minute: calendar.component(.minute, from: countdownTime),
                                         second: 0,
                                         of: countdownDate) ?? countdownDate
        
        var updatedEvent = event
        updatedEvent.title = title
        updatedEvent.startDate = eventDateTime
        updatedEvent.endDate = eventDateTime // Countdown events are single point in time
        updatedEvent.emoji = selectedEmoji
        updatedEvent.notes = notes
        updatedEvent.notifyBefore = notifyBefore
        
        calendarStore.updateEvent(updatedEvent)
        dismiss()
    }
}

