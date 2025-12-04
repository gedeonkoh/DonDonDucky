//
//  AddEventView.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import SwiftUI

struct AddEventView: View {
    @EnvironmentObject var calendarStore: CalendarStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let selectedDate: Date
    
    @State private var title = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedColor: EventColor = .orange
    @State private var isAllDay = false
    @State private var notes = ""
    @State private var notifyBefore: Int? = 15
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        let end = calendar.date(byAdding: .hour, value: 1, to: start) ?? selectedDate
        _startDate = State(initialValue: start)
        _endDate = State(initialValue: end)
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
                        // Duck header
                        Image("duck_happy")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                        
                        Text("New Event")
                            .font(.system(.title2, design: .rounded, weight: .heavy))
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                        
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            TextField("Focus Session", text: $title)
                                .font(.system(.body, design: .rounded))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                                )
                        }
                        
                        // All Day Toggle
                        Toggle(isOn: $isAllDay) {
                            Text("All Day")
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .tint(Color("DuckOrange"))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                        )
                        
                        // Date & Time
                        if !isAllDay {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start")
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                                
                                DatePicker("", selection: $startDate)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("End")
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                                
                                DatePicker("", selection: $endDate)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                                    )
                            }
                        }
                        
                        // Color Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                ForEach(EventColor.allCases, id: \.self) { color in
                                    Button(action: { selectedColor = color }) {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                            )
                                            .shadow(color: color.color.opacity(0.5), radius: selectedColor == color ? 8 : 0)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                            )
                        }
                        
                        // Reminder
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reminder")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            Picker("Reminder", selection: Binding(
                                get: { notifyBefore ?? -1 },
                                set: { notifyBefore = $0 == -1 ? nil : $0 }
                            )) {
                                Text("None").tag(-1)
                                Text("5 minutes before").tag(5)
                                Text("15 minutes before").tag(15)
                                Text("30 minutes before").tag(30)
                                Text("1 hour before").tag(60)
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                        Button(action: saveEvent) {
                            Text("Save Event")
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
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("DuckOrange"))
                }
            }
        }
    }
    
    private func saveEvent() {
        let event = CalendarEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            color: selectedColor,
            isAllDay: isAllDay,
            notes: notes,
            notifyBefore: notifyBefore,
            emoji: nil, // Regular events don't have emojis
            isCountdownEvent: false // Regular events only
        )
        calendarStore.addEvent(event)
        dismiss()
    }
}

struct EditEventView: View {
    @EnvironmentObject var calendarStore: CalendarStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    let event: CalendarEvent
    
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedColor: EventColor
    @State private var isAllDay: Bool
    @State private var notes: String
    @State private var notifyBefore: Int?
    @State private var showDeleteAlert = false
    
    init(event: CalendarEvent) {
        self.event = event
        _title = State(initialValue: event.title)
        _startDate = State(initialValue: event.startDate)
        _endDate = State(initialValue: event.endDate)
        _selectedColor = State(initialValue: event.color)
        _isAllDay = State(initialValue: event.isAllDay)
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
                        // Event Info Header - Day Range and Time Range
                        VStack(spacing: 12) {
                            // Day Range
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(Color("DuckOrange"))
                                Text(dayRangeString)
                                    .font(.system(.headline, design: .rounded, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.8))
                                Spacer()
                            }
                            
                            // Time Range
                            if !isAllDay {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock")
                                        .foregroundColor(Color("DuckOrange"))
                                    Text(timeRangeString)
                                        .font(.system(.body, design: .rounded, weight: .medium))
                                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.9))
                        )
                        
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            TextField("Focus Session", text: $title)
                                .font(.system(.body, design: .rounded))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                                )
                        }
                        
                        // All Day Toggle
                        Toggle(isOn: $isAllDay) {
                            Text("All Day")
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .tint(Color("DuckOrange"))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                        )
                        
                        // Date & Time
                        if !isAllDay {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start")
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                                
                                DatePicker("", selection: $startDate)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("End")
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                                
                                DatePicker("", selection: $endDate)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white.opacity(0.8))
                                    )
                            }
                        }
                        
                        // Color Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                ForEach(EventColor.allCases, id: \.self) { color in
                                    Button(action: { selectedColor = color }) {
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                            )
                                            .shadow(color: color.color.opacity(0.5), radius: selectedColor == color ? 8 : 0)
                                    }
                                }
                            }
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
                        Button(action: updateEvent) {
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
                            Text("Delete Event")
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
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("DuckOrange"))
                }
            }
            .alert("Delete Event?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    calendarStore.deleteEvent(event)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this event?")
            }
        }
    }
    
    // MARK: - Computed Properties for Display
    
    private var dayRangeString: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: startDate)
        } else {
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: startDate)
            formatter.dateFormat = "MMM d, yyyy"
            let endStr = formatter.string(from: endDate)
            return "\(startStr) - \(endStr)"
        }
    }
    
    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    private func updateEvent() {
        var updatedEvent = event
        updatedEvent.title = title
        updatedEvent.startDate = startDate
        updatedEvent.endDate = endDate
        updatedEvent.color = selectedColor
        updatedEvent.isAllDay = isAllDay
        updatedEvent.notes = notes
        updatedEvent.notifyBefore = notifyBefore
        // Regular events only - countdown events use EditCountdownView
        calendarStore.updateEvent(updatedEvent)
        dismiss()
    }
}

#Preview {
    AddEventView(selectedDate: Date())
        .environmentObject(CalendarStore())
}

