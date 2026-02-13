import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color.blue)
        }
        .modelContainer(for: [
            Transaction.self,
            UserProfile.self
        ])
    }
}
