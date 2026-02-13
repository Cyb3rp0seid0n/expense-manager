import Foundation

struct OCRParser {

    static func parse(text: String) -> RawTransaction {
        
        let lines = text.split(separator: "\n").map { String($0) }

        let amount = extractAmount(from: lines, fullText: text)
        let date = extractDate(from: lines, fullText: text)
        let merchant = extractMerchant(from: lines)

        return RawTransaction(
            amount: amount,
            date: date,
            description: merchant,
            source: .ocr
        )
    }

    private static func extractAmount(from lines: [String], fullText: String) -> Double? {
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            if lowercased.contains("paid") || lowercased == "paid" {
                for i in (index + 1)..<min(index + 3, lines.count) {
                    if let amount = parseAmount(from: lines[i]) {
                        return amount
                    }
                }
            }
        }
        
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            if lowercased.contains("total") || lowercased.contains("grand total") {
                if let amount = parseAmount(from: line) {
                    return amount
                }
                if index + 1 < lines.count {
                    if let amount = parseAmount(from: lines[index + 1]) {
                        return amount
                    }
                }
            }
        }
        let paidPattern = "Paid[\\s\\n]+₹\\s*([0-9,]+\\.?[0-9]*)"
        if let amount = extractAmountWithRegex(from: fullText, pattern: paidPattern) {
            return amount
        }
        
        for line in lines.reversed() {
            if line.contains("₹"), let amount = parseAmount(from: line) {
                return amount
            }
        }
        
        return nil
    }
    
    private static func parseAmount(from line: String) -> Double? {
        let cleaned = line
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "Rs", with: "")
            .replacingOccurrences(of: "Rs.", with: "")
            .trimmingCharacters(in: .whitespaces)

        let pattern = "[0-9]+\\.?[0-9]*"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
           let range = Range(match.range, in: cleaned) {
            let numberString = String(cleaned[range])
            if let value = Double(numberString), value > 0 {
                return value
            }
        }
        
        return nil
    }
    
    private static func extractAmountWithRegex(from text: String, pattern: String) -> Double? {
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let amountRange = Range(match.range(at: 1), in: text) {
            let amountString = String(text[amountRange]).replacingOccurrences(of: ",", with: "")
            return Double(amountString)
        }
        return nil
    }

    private static func extractDate(from lines: [String], fullText: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")


        let formats = [
            "MMMM d, yyyy",           // February 7, 2026
            "d MMMM, yyyy",           // 7 February, 2026
            "MMMM d yyyy",            // February 7 2026
            "d MMM yyyy",             // 7 Feb 2026
            "MMM d, yyyy",            // Feb 7, 2026
            "dd/MM/yyyy",             // 07/02/2026
            "dd-MM-yyyy",             // 07-02-2026
            "dd/MM/yy",               // 07/02/26
            "dd-MM-yy",               // 07-02-26
            "yyyy-MM-dd"              // 2026-02-07
        ]

        for (index, line) in lines.enumerated() {
            if line.lowercased().contains("payment date") || line.lowercased().contains("date") {
                for i in (index)..<min(index + 3, lines.count) {
                    for format in formats {
                        formatter.dateFormat = format
                        let candidates = [lines[i], lines[i].trimmingCharacters(in: .whitespaces)]
                        for candidate in candidates {
                            if let date = formatter.date(from: candidate) {
                                return date
                            }
                        }
                    }
                }
            }
        }
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: trimmed) {
                    return date
                }
            }
        }
        
        let datePattern = "(January|February|March|April|May|June|July|August|September|October|November|December)\\s+(\\d{1,2}),?\\s+(\\d{4})\\s+at\\s+(\\d{1,2}:\\d{2}\\s*[AP]M)"
        if let regex = try? NSRegularExpression(pattern: datePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: fullText, range: NSRange(fullText.startIndex..., in: fullText)),
           let dateRange = Range(match.range, in: fullText) {
            let dateString = String(fullText[dateRange])
            formatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }


    private static func extractMerchant(from lines: [String]) -> String? {
        let skipWords = ["order", "bill", "receipt", "invoice", "tax", "gst", "total", "paid"]
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let lowercased = trimmed.lowercased()
            
            if trimmed.isEmpty || trimmed.count < 2 {
                continue
            }
            
            if skipWords.contains(where: { lowercased.contains($0) }) {
                continue
            }
            
            if trimmed.contains("₹") || trimmed.contains("Rs") {
                continue
            }

            let digitCount = trimmed.filter { $0.isNumber }.count
            if Double(digitCount) / Double(trimmed.count) > 0.3 {
                continue
            }

            return trimmed
        }
        
        return lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
    }
}
