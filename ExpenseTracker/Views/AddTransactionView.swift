import SwiftData
import SwiftUI

struct AddTransactionView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let transactionToEdit: Transaction?
    @State private var amountText = ""
    @State private var date = Date()
    @State private var merchant = ""
    @State private var showAmountAlert = false
    @State private var showDuplicateAlert = false
    @State private var pendingTransaction: RawTransaction?
    
    init(transaction: Transaction? = nil) {
        self.transactionToEdit = transaction

        _amountText = State(initialValue: transaction.map { String($0.amount) } ?? "")
        _date = State(initialValue: transaction?.transactionDate ?? Date())
        _merchant = State(initialValue: transaction?.merchant ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("Enter amount", text: $amountText)
                        .keyboardType(.decimalPad)
                }

                Section("Date") {
                    DatePicker("Transaction Date", selection: $date, displayedComponents: .date)
                }

                Section("Merchant (Optional)") {
                    TextField("Merchant name", text: $merchant)
                }
            }
            .navigationTitle(transactionToEdit == nil ? "Add Transaction" : "Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Amount Required", isPresented: $showAmountAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a valid amount before saving the transaction.")
            }
            .alert("Duplicate Transaction", isPresented: $showDuplicateAlert) {
                Button("Cancel", role: .cancel) {
                    pendingTransaction = nil
                }
                Button("Add Anyway") {
                    forceAddTransaction()
                }
            } message: {
                Text("A recent similar transaction already exists for this merchant and amount. Add it anyway?")
            }
        }
    }

    private func saveTransaction() {
        guard let amount = Double(amountText), amount > 0 else {
            showAmountAlert = true
            return
        }

        if let transaction = transactionToEdit {
            // EDIT existing
            transaction.amount = amount
            transaction.transactionDate = date
            transaction.merchant = merchant.isEmpty ? nil : merchant
            dismiss()
        } else {
            // CREATE new - use ingestion service for deduplication
            let rawTransaction = RawTransaction(
                amount: amount,
                date: date,
                description: merchant.isEmpty ? nil : merchant,
                source: .manual
            )
            
            let ingestionService = TransactionIngestionService(modelContext: modelContext)
            let result = ingestionService.ingest(rawTransaction, into: modelContext)
            
            switch result {
            case .success:
                dismiss()
            case .duplicate:
                pendingTransaction = rawTransaction
                showDuplicateAlert = true
            case .invalid:
                showAmountAlert = true
            }
        }
    }
    
    private func forceAddTransaction() {
        guard let rawTransaction = pendingTransaction else { return }
        
        // Directly insert without duplicate check
        let transaction = Transaction(
            amount: rawTransaction.amount ?? 0,
            transactionDate: rawTransaction.date ?? Date(),
            merchant: rawTransaction.description,
            source: rawTransaction.source
        )
        
        modelContext.insert(transaction)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to force save transaction: \(error)")
        }
        
        pendingTransaction = nil
    }
}
