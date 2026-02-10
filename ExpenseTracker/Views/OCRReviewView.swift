import SwiftUI
import SwiftData

struct OCRReviewView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var amountText: String
    @State private var date: Date
    @State private var merchant: String
    @State private var showAmountError = false


    private let rawTransaction: RawTransaction
    private let ingestionService: TransactionIngestionService

    init(rawTransaction: RawTransaction, modelContext: ModelContext) {
        self.rawTransaction = rawTransaction
        self.ingestionService = TransactionIngestionService(modelContext: modelContext)

        _amountText = State(
            initialValue: rawTransaction.amount.map { String($0) } ?? ""
        )
        _date = State(
            initialValue: rawTransaction.date ?? Date()
        )
        _merchant = State(
            initialValue: rawTransaction.description ?? ""
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                }

                Section("Date") {
                    DatePicker("Transaction Date", selection: $date, displayedComponents: .date)
                }

                Section("Merchant") {
                    TextField("Merchant", text: $merchant)
                }
            }
            .navigationTitle("Review Transaction")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        saveTransaction()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Amount required",
                   isPresented: $showAmountError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a valid amount before saving.")
            }
        }
    }

    private func saveTransaction() {
        guard let amount = Double(amountText), amount > 0 else {
            showAmountError = true
            return
        }

        let transaction = Transaction(
            amount: amount,
            transactionDate: date,
            merchant: merchant.isEmpty ? nil : merchant,
            source: .ocr
        )

        modelContext.insert(transaction)
        dismiss()
    }

}
