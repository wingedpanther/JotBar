import SwiftUI

struct TaskRowView: View {
    let index: Int
    let task: Task
    let taskColors: [Color]
    let onUpdate: (Task) -> Void
    let onDelete: () -> Void
    
    @State private var showEditPopover = false
    @State private var draftHasDeadline = false
    @State private var draftDeadline = Date()
    @State private var draftColorIndex = 0
    @State private var draftReminderOffset: TimeInterval = 0

    var body: some View {
        HStack(alignment: .top) {
            ZStack {
                if let deadline = task.deadline {
                    TimeRingView(createdAt: task.createdAt, deadline: deadline, ringColor: taskColors[task.colorIndex])
                }
                Text("\(index + 1)")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
            .frame(width: 24, height: 24)
            .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                
                HStack(spacing: 4) {
                    Text(task.createdAt.formatted(.dateTime.month().day().hour().minute()))
                    
                    if let deadline = task.deadline {
                        let isSameDay = Calendar.current.isDate(task.createdAt, inSameDayAs: deadline)
                        Text("→")
                        Text(deadline.formatted(isSameDay ? .dateTime.hour().minute() : .dateTime.month().day().hour().minute()))
                            .foregroundColor(taskColors[task.colorIndex])
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(6)
            }
            
            Spacer()
            
            HStack(alignment: .center, spacing: 14) {
                Button(action: { showEditPopover = true }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showEditPopover, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Edit Task Options").font(.headline)
                        Toggle("Enable Deadline", isOn: $draftHasDeadline).toggleStyle(.switch)
                        
                        if draftHasDeadline {
                            DatePicker("Time", selection: $draftDeadline, in: Date()...).datePickerStyle(.compact)
                            Picker("Remind me", selection: $draftReminderOffset) {
                                Text("At deadline").tag(TimeInterval(0))
                                Text("5 mins before").tag(TimeInterval(300))
                                Text("15 mins before").tag(TimeInterval(900))
                                Text("30 mins before").tag(TimeInterval(1800))
                            }
                        }
                        
                        Text("Ring Color").font(.caption).foregroundColor(.secondary).padding(.top, 5)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<taskColors.count, id: \.self) { i in
                                Circle()
                                    .fill(taskColors[i])
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(Color.primary, lineWidth: draftColorIndex == i ? 2 : 0))
                                    .onTapGesture { draftColorIndex = i }
                                    .cursor(.pointingHand)
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Button("Done") {
                                var updatedTask = task
                                updatedTask.deadline = draftHasDeadline ? draftDeadline : nil
                                updatedTask.colorIndex = draftColorIndex
                                updatedTask.reminderOffset = draftReminderOffset
                                onUpdate(updatedTask)
                                showEditPopover = false
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    .frame(width: 250)
                    .onAppear {
                        draftHasDeadline = task.deadline != nil
                        draftDeadline = task.deadline ?? Date().addingTimeInterval(3600)
                        draftColorIndex = task.colorIndex
                        draftReminderOffset = task.reminderOffset
                    }
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }
}
