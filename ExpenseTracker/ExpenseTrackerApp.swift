import SwiftUI
import SwiftData

@main
struct ExpenseVaultApp: App {
    var body: some Scene {
        WindowGroup {
            TransactionListView()
        }
        .modelContainer(PersistenceController.shared)
    }
}
