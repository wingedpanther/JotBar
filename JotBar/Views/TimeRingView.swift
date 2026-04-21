
import SwiftUI
import Combine

struct TimeRingView: View {
    let createdAt: Date
    let deadline: Date
    let ringColor: Color
    @State private var progress: Double = 0.0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Circle().stroke(ringColor.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1.0), value: progress)
        }
        .onReceive(timer) { _ in updateProgress() }
        .onAppear { updateProgress() }
    }
    
    func updateProgress() {
        let totalTime = deadline.timeIntervalSince(createdAt)
        let elapsedTime = Date().timeIntervalSince(createdAt)
        if totalTime > 0 {
            let percentage = elapsedTime / totalTime
            progress = min(max(percentage, 0.0), 1.0)
        } else { progress = 1.0 }
    }
}
