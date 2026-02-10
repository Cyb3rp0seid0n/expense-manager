import Foundation
import SwiftData

@Model
final class Transaction{
    @Attribute(.unique)
    var id: UUID
    
    var amount: Double
    var transactionDate: Date
    var merchant: String?
    var merchantNormalized: String?
    
    var source: SourceType
    var createdAt: Date
    
    init(id: UUID = UUID(), amount: Double, transactionDate: Date, merchant: String? = nil, source: SourceType, createdAt: Date = Date()) {
        
        self.id = id
        self.amount = amount
        self.transactionDate = transactionDate
        self.merchant = merchant
        self.merchantNormalized = merchant?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
        self.source = source
        self.createdAt = createdAt
    }
}
