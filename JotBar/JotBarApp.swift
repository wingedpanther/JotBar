
import SwiftUI

@main
struct JotBarApp: App {
    var body: some Scene {
       
        MenuBarExtra("JotBar", systemImage: "checklist") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
