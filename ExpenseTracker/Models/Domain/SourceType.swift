import Foundation

enum SourceType: String, Codable {
    case manual
    case ocr
    case bank

    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .ocr: return "OCR"
        case .bank: return "Bank"
        }
    }
}

