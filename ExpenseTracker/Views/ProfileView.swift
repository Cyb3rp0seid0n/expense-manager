import SwiftUI
import SwiftData

struct ProfileView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    @State private var name: String = ""
    @State private var allowance: String = ""
    
    private var existingProfile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        Form {
            
            Section(header: Text("User Info")) {
                
                TextField("Name", text: $name)
                
                TextField("Monthly Allowance", text: $allowance)
                    .keyboardType(.decimalPad)
            }
            
            Section {
                HStack {
                    Spacer()
                    
                    Button("Save") {
                        saveProfile()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(width: 150)   // 👈 controls length
                    
                    Spacer()
                }
                .listRowBackground(Color.clear) // removes full row styling
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            if let profile = existingProfile {
                name = profile.name
                allowance = String(profile.monthlyAllowance)
            }
        }
    }
    
    private func saveProfile() {
        guard let allowanceValue = Double(allowance) else { return }
        
        if let profile = existingProfile {
            profile.name = name
            profile.monthlyAllowance = allowanceValue
        } else {
            let newProfile = UserProfile(
                name: name,
                monthlyAllowance: allowanceValue
            )
            modelContext.insert(newProfile)
        }
        dismiss()
    }
}

