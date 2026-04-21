import SwiftUI
import UserNotifications
import Combine
import ServiceManagement

struct ContentView: View {
    @State private var tasks: [Task] = []
    @State private var newTaskTitle: String = ""
    
    let taskColors: [Color] = [.blue, .purple, .pink, .red, .orange, .green]
    
    // Validation Limits
    let minTaskLength = 3
    let maxTaskLength = 60
    
    // Alerts
    @State private var showingDeleteAlert = false
    @State private var taskToDelete: Task?
    @State private var showingDeleteAllAlert = false
    
    let saveKey = "JotBarSavedTasksV4"
    
    // Settings
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @State private var showSettings = false
    
    // Dynamically gets the version from Xcode settings
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                
                // Input Area
                VStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Jot down your task and press Enter...", text: $newTaskTitle)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: newTaskTitle) { newValue in
                                if newValue.count > maxTaskLength {
                                    newTaskTitle = String(newValue.prefix(maxTaskLength))
                                }
                            }
                            .onSubmit { addTask() }
                        
                        if !newTaskTitle.isEmpty {
                            HStack {
                                let trimmedCount = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).count
                                if trimmedCount < minTaskLength {
                                    Text("Needs at least \(minTaskLength) characters")
                                        .foregroundColor(.red)
                                } else if newTaskTitle.count == maxTaskLength {
                                    Text("Maximum length reached")
                                        .foregroundColor(.orange)
                                }
                                Spacer()
                                Text("\(newTaskTitle.count)/\(maxTaskLength)")
                                    .foregroundColor(newTaskTitle.count == maxTaskLength ? .orange : .secondary)
                            }
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .animation(.easeInOut, value: newTaskTitle)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                Divider()

                // Task List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                            TaskRowView(
                                index: index,
                                task: task,
                                taskColors: taskColors,
                                onUpdate: { updatedTask in
                                    updateTask(updatedTask)
                                },
                                onDelete: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        taskToDelete = task
                                        showingDeleteAlert = true
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 12)
                }
                
                Divider()
                
                // Footer
                if !tasks.isEmpty {
                    HStack {
                        Text("\(tasks.count) pending \(tasks.count == 1 ? "task" : "tasks")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Settings Gear
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .cursor(.pointingHand)
                        .popover(isPresented: $showSettings, arrowEdge: .bottom) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Settings")
                                    .font(.headline)
                                
                                Toggle("Launch at Login", isOn: $launchAtLogin)
                                    .onChange(of: launchAtLogin) { newValue in
                                        do {
                                            if newValue {
                                                try SMAppService.mainApp.register()
                                            } else {
                                                try SMAppService.mainApp.unregister()
                                            }
                                        } catch {
                                            print("Failed to update Launch at Login: \(error)")
                                        }
                                    }
                                
                                Toggle("Play Notification Sound", isOn: $soundEnabled)
                                
                                // Visual divider and Quit Button
                                Divider()
                                    .padding(.vertical, 4)
                                
                                HStack {
                                    Spacer()
                                    Button("Quit JotBar") {
                                        NSApplication.shared.terminate(nil)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.red.opacity(0.8))
                                    .cursor(.pointingHand)
                                    Spacer()
                                }
                            }
                            .toggleStyle(.switch)
                            .padding()
                            .frame(width: 220)
                        }
                        
                        Button("Clear All") {
                            withAnimation(.easeInOut(duration: 0.2)) { showingDeleteAllAlert = true }
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundColor(.red.opacity(0.8))
                        .cursor(.pointingHand)
                        .padding(.leading, 8)
                    }
                    .overlay(
                        Text(appVersion)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.5))
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .blur(radius: (showingDeleteAlert || showingDeleteAllAlert) ? 3 : 0)
            .disabled(showingDeleteAlert || showingDeleteAllAlert)
            
            // Single Delete Alert
            if showingDeleteAlert, let task = taskToDelete {
                VStack(spacing: 15) {
                    Text("Delete Task").font(.headline)
                    Text("Are you sure you want to delete\n'\(task.title)'?").font(.subheadline).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 15) {
                        Button("Cancel") { withAnimation { showingDeleteAlert = false; taskToDelete = nil } }.keyboardShortcut(.escape, modifiers: [])
                        Button("Delete") { withAnimation { deleteTask(task); showingDeleteAlert = false } }.buttonStyle(.borderedProminent).tint(.red).keyboardShortcut(.defaultAction)
                    }
                    .padding(.top, 5)
                }
                .padding(20).background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.windowBackgroundColor))).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.3), lineWidth: 1)).shadow(radius: 10).frame(maxWidth: 260).transition(.scale.combined(with: .opacity))
            }
            
            // Delete All Alert
            if showingDeleteAllAlert {
                VStack(spacing: 15) {
                    Text("Clear All Tasks").font(.headline)
                    Text("Are you sure you want to delete all \(tasks.count) tasks?\nThis cannot be undone.").font(.subheadline).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 15) {
                        Button("Cancel") { withAnimation { showingDeleteAllAlert = false } }.keyboardShortcut(.escape, modifiers: [])
                        Button("Clear All") {
                            withAnimation {
                                tasks.removeAll()
                                saveTasks()
                                let center = UNUserNotificationCenter.current()
                                center.removeAllPendingNotificationRequests()
                                center.removeAllDeliveredNotifications()
                                showingDeleteAllAlert = false
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .keyboardShortcut(.defaultAction)
                    }
                    .padding(.top, 5)
                }
                .padding(20).background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.windowBackgroundColor))).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.3), lineWidth: 1)).shadow(radius: 10).frame(maxWidth: 260).transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 360, height: 480)
        .onAppear {
            loadTasks()
            requestNotificationPermission()
        }
    }

    // MARK: - Task Actions
    func addTask() {
        let cleanTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanTitle.count >= minTaskLength else { return }
        
        let newTask = Task(title: cleanTitle)
        tasks.append(newTask)
        
        newTaskTitle = ""
        saveTasks()
    }
    
    func updateTask(_ updatedTask: Task) {
        if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
            removeNotification(for: tasks[index])
            tasks[index] = updatedTask
            scheduleNotification(for: updatedTask)
            saveTasks()
        }
    }

    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        removeNotification(for: task)
        saveTasks()
        taskToDelete = nil
    }
    
    // MARK: - Data & Notifications
    func saveTasks() {
        if let encodedData = try? JSONEncoder().encode(tasks) { UserDefaults.standard.set(encodedData, forKey: saveKey) }
    }
    
    func loadTasks() {
        if let savedData = UserDefaults.standard.data(forKey: saveKey), let decodedTasks = try? JSONDecoder().decode([Task].self, from: savedData) { tasks = decodedTasks }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted { print("Notification permission granted.") } else if let error = error { print("Notification permission error: \(error.localizedDescription)") }
        }
    }
    
    func scheduleNotification(for task: Task) {
        guard let deadline = task.deadline else { return }
        
        // Calculate the actual alert time by subtracting the offset
        let triggerDate = deadline.addingTimeInterval(-task.reminderOffset)
        let timeInterval = triggerDate.timeIntervalSinceNow
        
        guard timeInterval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "JotBar Reminder"
        
        // Customize the text based on the offset
        if task.reminderOffset == 0 {
            content.body = "Time is up for: \(task.title)"
        } else {
            let minutes = Int(task.reminderOffset / 60)
            content.body = "'\(task.title)' is due in \(minutes) minutes!"
        }
        
        if soundEnabled {
            content.sound = .default
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func removeNotification(for task: Task) {
        let center = UNUserNotificationCenter.current()
        let identifiers = [task.id.uuidString]
                
        // 1. Removes it if it hasn't triggered yet
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
                
        // 2. Removes it if macOS already pushed it to the delivery queue
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
