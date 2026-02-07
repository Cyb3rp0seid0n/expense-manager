import SwiftUI
import SwiftData

struct AddTransactionView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var date = Date()
    @State private var merchant = ""

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
            .navigationTitle("Add Transaction")
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
        }
    }

    private func saveTransaction() {
        guard let amount = Double(amountText) else {
            return
        }

        let transaction = Transaction(
            amount: amount,
            transactionDate: date,
            merchant: merchant.isEmpty ? nil : merchant,
            source: .manual
        )

        modelContext.insert(transaction)
        dismiss()
    }
}
