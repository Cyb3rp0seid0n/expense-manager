import Foundation

struct OCRParser {

    static func parse(text: String) -> RawTransaction {
        let lines = text.split(separator: "\n").map { String($0) }

        let amount = extractAmount(from: lines)
        let date = extractDate(from: lines)
        let merchant = extractMerchant(from: lines)

        return RawTransaction(
            amount: amount,
            date: date,
            description: merchant,
            source: .ocr
        )
    }

    // MARK: - Heuristics

    private static func extractAmount(from lines: [String]) -> Double? {
        for line in lines {
            let cleaned = line
                .replacingOccurrences(of: "₹", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)

            if let value = Double(cleaned), value > 0 {
                return value
            }
        }
        return nil
    }

    private static func extractDate(from lines: [String]) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let formats = [
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "dd/MM/yy",
            "dd-MM-yy"
        ]

        for line in lines {
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: line) {
                    return date
                }
            }
        }

        return nil
    }


    private static func extractMerchant(from lines: [String]) -> String? {
        return lines.first
    }
}
