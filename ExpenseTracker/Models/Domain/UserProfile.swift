import SwiftData
import Foundation

@Model
final class UserProfile {
    var name: String
    var monthlyAllowance: Double
    
    init(name: String, monthlyAllowance: Double) {
        self.name = name
        self.monthlyAllowance = monthlyAllowance
    }
}
