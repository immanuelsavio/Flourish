import SwiftUI
import Combine

struct SettingsAndAppearanceView: View {
    @EnvironmentObject var dataService: DataService
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var authService = AuthenticationService.shared
    @State private var showEditProfile = false
    @State private var selectedCurrency = Locale.current.currency?.identifier ?? "USD"
    @State private var hasUnsavedChanges = false

    let supportedCurrencies = ["USD", "EUR", "GBP", "INR", "JPY", "AUD", "CAD"]

    private var currentUser: User? {
        authService.currentUser
    }

    var body: some View {
        List {
            Section(header: Text("Profile")) {
                if let user = currentUser {
                    Button(action: { showEditProfile = true }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(user.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }

            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $appSettings.colorScheme) {
                    ForEach(ColorSchemeOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                
                Toggle("Senior Mode (Larger Text)", isOn: $appSettings.seniorMode)
                
                if appSettings.seniorMode {
                    Text("Text and UI elements will be displayed in a larger size for better readability.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Section(header: Text("Currency")) {
                Picker("Currency", selection: $selectedCurrency) {
                    ForEach(supportedCurrencies, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                .onChange(of: selectedCurrency) { _ in
                    hasUnsavedChanges = true
                }
            }
            
            if hasUnsavedChanges {
                Section {
                    Button(action: saveSettings) {
                        HStack {
                            Spacer()
                            Text("Save Changes")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .listRowBackground(Color.clear)
                }
            }

            Section(header: Text("App Info")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundColor(.gray)
                }
            }

            Section(header: Text("About")) {
                Text("Flourish helps students and early professionals manage money locally, without cloud sync.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Settings & Appearance")
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .onAppear {
            selectedCurrency = dataService.currencyCode
        }
    }
    
    private func saveSettings() {
        // Explicitly save to UserDefaults first
        UserDefaults.standard.set(selectedCurrency, forKey: "currencyCode")
        
        // Then update the published property (this will trigger UI refresh)
        dataService.currencyCode = selectedCurrency
        
        // Give it a moment to propagate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Force another refresh to ensure all views update
            self.dataService.objectWillChange.send()
        }
        
        // Clear unsaved changes flag
        hasUnsavedChanges = false
    }
}
