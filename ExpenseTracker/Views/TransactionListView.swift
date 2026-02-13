import SwiftUI
import SwiftData

struct TransactionListView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.transactionDate, order: .reverse)
    private var transactions: [Transaction]

    @State private var showAddTransaction = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.94, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                Group {
                    if transactions.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                List {
                                    ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                                        NavigationLink {
                                            AddTransactionView(transaction: transaction)
                                        } label: {
                                            TransactionRowView(transaction: transaction)
                                        }
                                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                                        .listRowSeparator(index < transactions.count - 1 ? .visible : .hidden)
                                        .listRowBackground(Color.white)
                                    }
                                    .onDelete(perform: deleteTransactions)
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .scrollDisabled(true)
                                .frame(height: CGFloat(transactions.count) * 80)
                            }
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05),
                                    radius: 8,
                                    x: 0,
                                    y: 4)
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Spendings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
                ToolbarItem {
                    NavigationLink {
                        ScanReceiptView()
                    } label: {
                        Image(systemName: "doc.text.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
        }
    }

    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            let transaction = transactions[index]
            modelContext.delete(transaction)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Expenses Yet")
                .font(.title2)
                .bold()
            
            Text("Add your first expense to get started.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 4)
        .padding()
    }
}
