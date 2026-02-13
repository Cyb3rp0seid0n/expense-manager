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
            ZStack {
                
                // Step 1: Soft blue background
                Color(red: 0.94, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        if let user {
                            
                            // Header
                            Text("Hello, \(user.name)")
                                .font(.largeTitle)
                                .bold()
                            
                            let currentSpend = currentMonthTotal()
                            let remaining = user.monthlyAllowance - currentSpend
                            let progress = user.monthlyAllowance > 0
                                ? min(currentSpend / user.monthlyAllowance, 1.0)
                                : 0
                            
                            // Step 2: Spending Card
                            VStack(alignment: .leading, spacing: 12) {
                                
                                Text("Allowance: ₹\(user.monthlyAllowance, specifier: "%.0f")")
                                
                                Text("Spent: ₹\(currentSpend, specifier: "%.0f")")
                                
                                Text("Remaining: ₹\(remaining, specifier: "%.0f")")
                                    .foregroundColor(remaining < 0 ? .red : .primary)
                                
                                ProgressView(value: progress)
                                    .tint(progress > 0.9
                                          ? Color.red.opacity(0.7)
                                          : Color.blue.opacity(0.7))
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05),
                                    radius: 8,
                                    x: 0,
                                    y: 4)
                            
                            // Step 3: Chart Card
                            VStack(alignment: .leading, spacing: 12) {
                                
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
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05),
                                    radius: 8,
                                    x: 0,
                                    y: 4)
                            
                        } else {
                            
                            // No Profile Card
                            VStack(spacing: 16) {
                                Text("No user profile found.")
                                    .font(.headline)
                                
                                NavigationLink("Create Profile") {
                                    ProfileView()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05),
                                    radius: 8,
                                    x: 0,
                                    y: 4)
                            .padding(.top, 100)
                        }
                    }
                    .padding()
                }
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

