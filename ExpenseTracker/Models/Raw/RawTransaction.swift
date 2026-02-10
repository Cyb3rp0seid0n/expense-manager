import Foundation

struct RawTransaction: Identifiable {
    let id = UUID()

    let amount: Double?
    let date: Date?
    let description: String?
    let source: SourceType
}

