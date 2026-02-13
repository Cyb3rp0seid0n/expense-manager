import SwiftUI
import SwiftData

struct OCRReviewView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State var rawTransaction: RawTransaction
    @State private var showDuplicateAlert = false
    @State private var pendingTransaction: RawTransaction?
    
    var body: some View {
        Form {
            Section("Detected Information") {
                if let amount = rawTransaction.amount {
                    LabeledContent("Amount", value: amount, format: .currency(code: "INR"))
                } else {
                    Text("Amount not detected")
                        .foregroundStyle(.secondary)
                }
                
                if let date = rawTransaction.date {
                    LabeledContent("Date", value: date, format: .dateTime)
                } else {
                    Text("Date not detected")
                        .foregroundStyle(.secondary)
                }
                
                if let description = rawTransaction.description {
                    LabeledContent("Merchant", value: description)
                } else {
                    Text("Merchant not detected")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Button("Confirm & Add") {
                    saveTransaction()
                }
                .disabled(rawTransaction.amount == nil || rawTransaction.date == nil)
                
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        }
        .navigationTitle("Review Transaction")
        .alert("Duplicate Transaction", isPresented: $showDuplicateAlert) {
            Button("Cancel", role: .cancel) {
                pendingTransaction = nil
            }
            Button("Add Anyway") {
                forceAddTransaction()
            }
        } message: {
            Text("A similar transaction already exists for this merchant and amount. Do you want to add it anyway?")
        }
    }
    
    private func saveTransaction() {
        let ingestionService = TransactionIngestionService(modelContext: modelContext)
        let result = ingestionService.ingest(rawTransaction, into: modelContext)
        
        switch result {
        case .success:
            dismiss()
        case .duplicate:
            pendingTransaction = rawTransaction
            showDuplicateAlert = true
        case .invalid:
            dismiss()
        }
    }
    
    private func forceAddTransaction() {
        guard let pending = pendingTransaction else { return }
        
        let transaction = Transaction(
            amount: pending.amount ?? 0,
            transactionDate: pending.date ?? Date(),
            merchant: pending.description,
            source: .ocr
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
