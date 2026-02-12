import SwiftUI
import SwiftData
import Charts

struct OverviewView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query private var transactions: [Transaction]
    @Query private var profiles: [UserProfile]
    
    private var user: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    if let user {
                        
                        Text("Hello, \(user.name)")
                            .font(.title)
                            .bold()
                        
                        let currentSpend = currentMonthTotal()
                        let remaining = user.monthlyAllowance - currentSpend
                        let progress = user.monthlyAllowance > 0
                            ? min(currentSpend / user.monthlyAllowance, 1.0)
                            : 0
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Allowance: ₹\(user.monthlyAllowance, specifier: "%.0f")")
                            Text("Spent: ₹\(currentSpend, specifier: "%.0f")")
                            Text("Remaining: ₹\(remaining, specifier: "%.0f")")
                                .foregroundColor(remaining < 0 ? .red : .primary)
                        }
                        
                        ProgressView(value: progress)
                            .tint(progress > 0.9 ? .red : .blue)
                        
                        Divider()
                        
                        Text("Spending Trend (Last 3 Months)")
                            .font(.headline)
                        
                        Chart(lastThreeMonthsData()) { item in
                            LineMark(
                                x: .value("Month", item.month),
                                y: .value("Total", item.total)
                            )
                            .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 220)
                        
                    } else {
                        
                        VStack(spacing: 16) {
                            Text("No user profile found.")
                                .font(.headline)
                            
                            NavigationLink("Create Profile") {
                                ProfileView()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    }
                }
                .padding()
            }
            .navigationTitle("Overview")
            .toolbar {
                NavigationLink {
                    ProfileView()
                } label: {
                    Image(systemName: "person.circle")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func currentMonthTotal() -> Double {
        let calendar = Calendar.current
        let now = Date()
        
        return transactions
            .filter { calendar.isDate($0.transactionDate, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func lastThreeMonthsData() -> [MonthlySpend] {
        let calendar = Calendar.current
        let now = Date()
        
        var result: [MonthlySpend] = []
        
        for offset in (0..<3).reversed() {
            if let date = calendar.date(byAdding: .month, value: -offset, to: now) {
                
                let monthTotal = transactions
                    .filter { calendar.isDate($0.transactionDate, equalTo: date, toGranularity: .month) }
                    .reduce(0) { $0 + $1.amount }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                
                result.append(
                    MonthlySpend(
                        month: formatter.string(from: date),
                        total: monthTotal
                    )
                )
            }
        }
        
        return result
    }
}

struct MonthlySpend: Identifiable {
    let id = UUID()
    let month: String
    let total: Double
}

