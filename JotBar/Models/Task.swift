import Foundation

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var createdAt: Date = Date()
    var deadline: Date?
    var colorIndex: Int = 0
    var reminderOffset: TimeInterval = 0 
}
