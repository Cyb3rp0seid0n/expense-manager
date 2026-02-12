import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            
            OverviewView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            TransactionListView()
                .tabItem {
                    Label("Spendings", systemImage: "list.bullet")
                }
        }
    }
}
