import SwiftUI
import SwiftData

struct TransactionListView: View {

    @Query(sort: \Transaction.transactionDate, order: .reverse)
    private var transactions: [Transaction]

    @State private var showAddTransaction = false

    var body: some View {
        NavigationStack {
            List(transactions) { transaction in
                VStack(alignment: .leading) {
                    Text("₹\(transaction.amount, specifier: "%.2f")")
                        .font(.headline)

                    Text(transaction.transactionDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(transaction.source.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                Button {
                    showAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
        }
    }
}
