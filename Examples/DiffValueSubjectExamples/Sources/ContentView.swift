import SwiftUI

public struct ContentView: View {
    @State private var selectedTab = 0
    
    public init() {}

    public var body: some View {
        NavigationView {
            VStack {
                // Tab selector
                Picker("Demo Type", selection: $selectedTab) {
                    Text("SwiftUI").tag(0)
                    Text("UIKit").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                // Content based on selection
                if selectedTab == 0 {
                    SwiftUIDemoView()
                } else {
                    UIKitDemoView()
                }
            }
            .navigationTitle("DiffArraySubject Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}


