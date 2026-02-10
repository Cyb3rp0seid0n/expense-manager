import SwiftUI
import SwiftData

struct TransactionListView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.transactionDate, order: .reverse)
    private var transactions: [Transaction]

    @State private var showAddTransaction = false

    var body: some View {
        NavigationStack {
            Group {
                if transactions.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(transactions) { transaction in
                            NavigationLink {
                                AddTransactionView(transaction: transaction)
                            } label: {
                                TransactionRowView(transaction: transaction)
                            }
                        }
                        .onDelete(perform: deleteTransactions)
                    }
                }
            }
            .navigationTitle("Spendings")
            .toolbar {

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
        }
    }

    // MARK: - Delete
    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            let transaction = transactions[index]
            modelContext.delete(transaction)
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        ContentUnavailableView(
            "No Expenses Yet",
            systemImage: "tray",
            description: Text("Add your first expense to get started.")
        )
    }
}

