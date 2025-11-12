//
//  FinanceAppApp.swift
//  FinanceApp
//
//  Main app entry point
//

import SwiftUI

@main
struct FlourishApp: App {  // Changed from FinanceAppApp
    @StateObject private var dataService = DataService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataService)
        }
    }
}
