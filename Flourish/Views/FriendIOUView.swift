//
//  FriendIOUView.swift
//  Flourish
//
//  View for tracking personal IOUs and debts separate from expense splits
//

import SwiftUI

struct FriendIOUView: View {
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    @State private var showAddIOU = false
    @State private var selectedIOU: FriendIOU?
    
    var body: some View {
        VStack {
            if let userId = authService.currentUser?.id {
                let ious = dataService.getActiveFriendIOUs(for: userId)
                
                if ious.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No IOUs")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Track money borrowed or lent to friends")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showAddIOU = true }) {
                            Label("Add IOU", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    List {
                        let owedToYou = ious.filter { $0.direction == .owedToYou }
                        let youOwe = ious.filter { $0.direction == .youOwe }
                        
                        if !owedToYou.isEmpty {
                            Section(header: Text("They Owe You")) {
                                ForEach(owedToYou) { iou in
                                    IOURow(iou: iou)
                                        .onTapGesture {
                                            selectedIOU = iou
                                        }
                                }
                            }
                        }
                        
                        if !youOwe.isEmpty {
                            Section(header: Text("You Owe Them")) {
                                ForEach(youOwe) { iou in
                                    IOURow(iou: iou)
                                        .onTapGesture {
                                            selectedIOU = iou
                                        }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("IOUs")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAddIOU = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddIOU) {
            AddIOUView()
        }
        .sheet(item: $selectedIOU) { iou in
            IOUDetailView(iou: iou)
        }
    }
}

struct IOURow: View {
    let iou: FriendIOU
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(iou.personName)
                    .font(.headline)
                
                if !iou.notes.isEmpty {
                    Text(iou.notes)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Text(iou.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(iou.amount.formatAsCurrency())
                    .font(.headline)
                    .foregroundColor(iou.direction == .owedToYou ? .green : .orange)
                
                Text(iou.direction.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddIOUView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var personName = ""
    @State private var amount = ""
    @State private var direction: IOUDirection = .owedToYou
    @State private var notes = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Person")) {
                    TextField("Friend's Name", text: $personName)
                }
                
                Section(header: Text("Amount & Direction")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Direction", selection: $direction) {
                        ForEach([IOUDirection.owedToYou, IOUDirection.youOwe], id: \.self) { dir in
                            Text(dir.rawValue).tag(dir)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Details")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    if let amountValue = Double(amount) {
                        VStack(alignment: .leading, spacing: 8) {
                            if direction == .owedToYou {
                                Text("📥 \(personName.isEmpty ? "They" : personName) will owe you \(amountValue.formatAsCurrency())")
                            } else {
                                Text("📤 You will owe \(personName.isEmpty ? "them" : personName) \(amountValue.formatAsCurrency())")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Add IOU")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveIOU()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !personName.isEmpty && !amount.isEmpty && Double(amount) != nil
    }
    
    private func saveIOU() {
        guard let userId = authService.currentUser?.id,
              let amountValue = Double(amount) else { return }
        
        let iou = FriendIOU(
            userId: userId,
            personName: personName,
            amount: amountValue,
            direction: direction,
            notes: notes,
            date: date
        )
        
        dataService.saveFriendIOU(iou)
        dismiss()
    }
}

struct IOUDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    let iou: FriendIOU
    
    @State private var showSettleConfirmation = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Details")) {
                    HStack {
                        Text("Person")
                        Spacer()
                        Text(iou.personName)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text(iou.amount.formatAsCurrency())
                            .fontWeight(.semibold)
                            .foregroundColor(iou.direction == .owedToYou ? .green : .orange)
                    }
                    
                    HStack {
                        Text("Direction")
                        Spacer()
                        Text(iou.direction.rawValue)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(iou.date.formatted(date: .long, time: .omitted))
                            .foregroundColor(.gray)
                    }
                    
                    if !iou.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(iou.notes)
                        }
                    }
                }
                
                Section {
                    Button(action: { showSettleConfirmation = true }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as Settled")
                        }
                        .foregroundColor(.green)
                    }
                    
                    Button(action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete IOU")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("IOU Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Settle IOU?", isPresented: $showSettleConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Settle") {
                    dataService.settleFriendIOU(iou)
                    dismiss()
                }
            } message: {
                Text("This will mark the IOU as settled and move it to history.")
            }
            .alert("Delete IOU?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    dataService.deleteFriendIOU(iou)
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
}

#Preview {
    NavigationView {
        FriendIOUView()
            .environmentObject(DataService.shared)
    }
}
