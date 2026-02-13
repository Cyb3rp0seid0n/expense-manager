import Foundation
import SwiftData

final class TransactionIngestionService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    private func normalize(_ raw: RawTransaction) -> Transaction? {
        guard
            let amount = raw.amount,
            amount > 0,
            let date = raw.date
        else {
            return nil
        }

        return Transaction(
            amount: amount,
            transactionDate: date,
            merchant: raw.description,
            source: raw.source
        )
    }
    private func isDuplicate(_ transaction: Transaction, context: ModelContext) -> Bool {
        guard let merchantKey = transaction.merchantNormalized else {
            return false
        }

        let window = dedupWindow(for: transaction.source)
        let startTime = transaction.transactionDate.addingTimeInterval(-window)
        let endTime = transaction.transactionDate.addingTimeInterval(window)
        let amount = transaction.amount
        

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { tx in
                tx.amount == amount &&
                tx.transactionDate >= startTime &&
                tx.transactionDate <= endTime &&
                tx.merchantNormalized == merchantKey
            }
        )

        do {
                let matches = try context.fetch(descriptor)
                return !matches.isEmpty
        } catch {
            return false
        }
    }
    
    private func dedupWindow(for source: SourceType) -> TimeInterval {
        switch source {
        case .ocr:
            return 10 * 60   // 10 minutes
        case .manual:
            return 3 * 60    // 3 minutes
        case .bank:
            return 1 * 60    // 1 minute
        }
    }
    
    enum IngestionResult {
        case success
        case duplicate
        case invalid
    }

    func ingest(_ raw: RawTransaction, into context: ModelContext) -> IngestionResult {
        guard
            let amount = raw.amount,
            let date = raw.date
        else {
            return .invalid
        }

        let transaction = Transaction(
            amount: amount,
            transactionDate: date,
            merchant: raw.description,
            source: raw.source
        )


        if isDuplicate(transaction, context: context) {
            return .duplicate
        }

        context.insert(transaction)
        
        do {
            try context.save()
            return .success
        } catch {
            return .invalid
        }
    }
}
