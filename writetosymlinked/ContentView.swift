//
//  ContentView.swift
//  writetosymlinked
//
//  Created by Huy Nguyen on 27/4/25.
//

import SwiftUI
import Foundation
import Darwin

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}

struct ContentView: View {
    var symlinkURL: URL
    @State private var currentStep = 0
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isSymlinkCreated = false
    @State private var showSuccess = false
    @State private var checkPath = "/var/mobile/Containers/example.txt"
    @State private var showCredits = false
    @State private var shortcutRunInThisSession = false
    @AppStorage("appDataPath") private var appDataPath: String = ""
    @AppStorage("skipStep3") private var skipStep3 = false
    @AppStorage("autoSymlinkEnabled") private var autoSymlinkEnabled = false
    @AppStorage("autoRunShortcut") private var autoRunShortcut = false

    
    private let steps = [
        "Setup App Data Path",
        "Create Symlink",
        "Copy Files",
        "Complete Process"
    ]
    
    func runShortcut(named name: String) {
        guard let urlEncodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://run-shortcut?name=writetosymlinked") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue.gradient)
                        
                        Text("write_to_symlinked")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        
                        Text("Follow these steps to write files using this symlinks exploit")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Credits") {
                            showCredits = true
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                    .padding(.top)
                    
                    // Progress Indicator
                    ProgressView(value: Double(currentStep), total: Double(steps.count - 1))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 2)
                        .padding(.horizontal)
                    
                    Text("Step \(currentStep + 1) of \(steps.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Main Content
                    VStack(spacing: 20) {
                        if currentStep == 0 {
                            step1View
                        } else if currentStep == 1 {
                            step2View
                        } else if currentStep == 2 {
                            step3View
                        } else {
                            step4View
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                
            }
            .background(Color(.systemBackground))
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        }
        .alert("It's now done!", isPresented: $showSuccess) {
            Button("Start Over") {
                resetProcess()
            }
            Button("Done", role: .cancel) {}
        } message: {
            Text("You can use this exploit for overwrite some app's data for fun, at least that's what i can do")
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
        .onAppear {
            UITextField.appearance().clearButtonMode = .whileEditing
        }
    }
    
    private var step1View: some View {
        VStack(spacing: 16) {
            StepHeader(
                number: 1,
                title: "Paste App's Data Path",
                description: "Enter the target app's data path to write files\nYou can checking app's data path by using Console on macOS or console log in Sideloadly (PC)"
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("App Data Path")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("e.g., /var/mobile/Containers/Data/Application/...", text: $appDataPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                
                Text("Once you write it to the folder, you can't delete it (or maybe you can if somehow you have r/w access)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            Button(action: {
                if !appDataPath.isEmpty {
                    currentStep = 1
                }
            }) {
                HStack {
                    Text("Continue")
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(appDataPath.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(appDataPath.isEmpty)
        }
    }

    private var step2View: some View {
        VStack(spacing: 16) {
            StepHeader(
                number: 2,
                title: "Create Symlink",
                description: "Create the symlink to this app's data (you can check in Files.app)"
            )

            VStack(spacing: 12) {
                InfoCard(
                    title: "Ready to Create Symlink",
                    details: [
                        ("Target Path", appDataPath)
                    ]
                )

                if isSymlinkCreated {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Symlink created successfully!")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }

            HStack(spacing: 12) {
                Button("Back") {
                    currentStep = 0
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)

                Button(action: {
                    if isSymlinkCreated {
                        currentStep = skipStep3 ? 3 : 2
                    } else {
                        createSymlink()
                    }
                }) {
                    HStack {
                        if isSymlinkCreated {
                            Text("Next Step")
                            Image(systemName: "arrow.right")
                        } else {
                            Image(systemName: "link")
                            Text("Create Symlink")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSymlinkCreated ? Color.green : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .onAppear {
            if autoSymlinkEnabled && !isSymlinkCreated {
                createSymlink()
            }
        }
    }

    private var step3View: some View {
        VStack(spacing: 16) {
            StepHeader(
                number: 3,
                title: "Copy Your Files",
                description: "Use Files.app to copy any files you want to write into this app's Documents folder"
            )

            VStack(spacing: 12) {
                InstructionCard(
                    icon: "doc.on.doc",
                    title: "Copy Files",
                    description: "Open Files.app and copy and paste any files you want to write into:",
                    highlight: "On My iPhone → writetosymlinked"
                )

                InstructionCard(
                    icon: "doc.text",
                    title: "Example File Created",
                    description: "An example file has been created for you:",
                    highlight: "example.txt"
                )
            }

            HStack(spacing: 12) {
                Button("Back") {
                    currentStep = 1
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)

                Button(action: {
                    currentStep = 3
                }) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .onAppear {
            if skipStep3 && currentStep == 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentStep = 3
                }
            }
        }
    }
    
    private var step4View: some View {
        VStack(spacing: 16) {
            StepHeader(
                number: 4,
                title: "Complete the Process",
                description: "Final step: Delete the files you just copied to write them to the target directory"
            )
            
            VStack(spacing: 12) {
                InstructionCard(
                    icon: "trash",
                    title: "Delete Files",
                    description: "Go to Files.app → writetosymlink → [Your file you just copy and paste] → Hold then press delete",
                    highlight: "An error will popup (that means it works)"
                )
                
                Text("After deleting the files, they will be written to the target app's directory!")
                    .font(.callout)
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Check File Existence")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Enter full path to check if file exists", text: $checkPath)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                
                Button("Check File") {
                    let fileExists = access(checkPath, F_OK) == 0
                    alertMessage = "File \(checkPath) exists: \(fileExists ? "True" : "False")"
                    showAlert = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.top)
            
            HStack(spacing: 12) {
                Button("Back") {
                    currentStep = 2
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)
                
                Button(action: {
                    showSuccess = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Complete")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                runShortcut(named: "writetosymlinked")
            }) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Run Shortcut (example.txt only)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("File Check"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            if autoRunShortcut && !shortcutRunInThisSession {
                runShortcut(named: "writetosymlinked")
                shortcutRunInThisSession = true
            }
        }
    }
    
    private func createSymlink() {
        do {
            try FileManager.default.removeItem(at: symlinkURL)
        } catch {
            // Ignore if file doesn't exist
        }
        
        do {
            try FileManager.default.createSymbolicLink(at: symlinkURL, withDestinationURL: URL(fileURLWithPath: appDataPath))
            isSymlinkCreated = true
            
            // Create example file after symlink is created
            createExampleFile()
            
            // Auto-advance to next step after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                currentStep = 2
            }
        } catch {
            alertMessage = "Failed to create symlink: \(error.localizedDescription)"
            showAlert = true
        }
    }
    private func createExampleFile() {
        let exampleFile = getDocumentsDirectory().appendingPathComponent("example.txt", conformingTo: .plainText)
        let exampleText = "This is an example file created after symlink.\nYou can copy more files here and delete them to write to target directory."
        try? exampleText.write(to: exampleFile, atomically: true, encoding: .utf8)
    }
    
    private func resetProcess() {
        currentStep = 0
        appDataPath = "/var/mobile/Containers"
        isSymlinkCreated = false
        checkPath = "/var/mobile/Containers/example.txt"
        try? FileManager.default.removeItem(at: symlinkURL)
    }
    
    init() {
        symlinkURL = getDocumentsDirectory().appendingPathComponent(".Trash", conformingTo: .symbolicLink)
        try? FileManager.default.removeItem(at: symlinkURL)
        let exampleFile = getDocumentsDirectory().appendingPathComponent("example.txt", conformingTo: .plainText)
        // create example file
        let exampleText = "Example text file"
        try? exampleText.write(to: exampleFile, atomically: true, encoding: .utf8)
    }
}

struct StepHeader: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Text("\(number)")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                    )
                
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct InstructionCard: View {
    let icon: String
    let title: String
    let description: String
    let highlight: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(highlight)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct InfoCard: View {
    let title: String
    let details: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(details, id: \.0) { detail in
                HStack {
                    Text(detail.0 + ":")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(detail.1)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
//                    VStack(spacing: 12) {
//                        Image(systemName: "star.circle.fill")
//                            .font(.system(size: 60))
//                            .foregroundStyle(.yellow.gradient)
//
//                        Text("Credits")
//                            .font(.largeTitle.bold())
//
//                        Text("Thanks to these amazing contributors")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.top, 20)
//
                    // Contributors
                    VStack(spacing: 20) {
                        CreditCard(
                            name: "Nathan",
                            role: "Original Exploit",
                            github: "verygenericname",
                            description: "Found it first"
                        )
                        
                        CreditCard(
                            name: "DuyTran",
                            role: "Implementation",
                            github: "khanhduytran0",
                            description: "Improve the method"
                        )
                        
                        CreditCard(
                            name: "HuyNguyen",
                            role: "Built this app",
                            github: "34306",
                            description: "Doing nothing"
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline)
                }
            }
        }
    }
}

struct CreditCard: View {
    let name: String
    let role: String
    let github: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                Text(name)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text(role)
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            Link(destination: URL(string: "https://github.com/\(github)")!) {
                HStack(spacing: 8) {
                    Image(systemName: "link.circle.fill")
                        .font(.title3)
                    Text("@\(github)")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue.gradient)
                .cornerRadius(25)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
}

struct SettingsView: View {
    @AppStorage("autoSymlinkEnabled") private var autoSymlinkEnabled = false
    @AppStorage("autoRunShortcut") private var autoRunShortcut = false
    @AppStorage("skipStep3") private var skipStep3 = false

    var body: some View {
        Form {
            Toggle("Auto-create symlink (Step 2)", isOn: $autoSymlinkEnabled)
            Toggle("Skip the 'Copy Your Files' guide (Step 3)", isOn: $skipStep3)
            Toggle("Auto-run Shortcut (Step 4)", isOn: $autoRunShortcut)
            Section(header: Text("Shortcuts")) {
                Link(destination: URL(string: "https://www.icloud.com/shortcuts/9df5343371c14a3b9e8d07f9b12e2cc4")!) {
                    Label("Get 'writetosymlinked' Shortcut", systemImage: "bolt.fill")
                        .foregroundColor(.purple)
                }
            }
        }
        .navigationTitle("Settings")
    }
}


#Preview {
    ContentView()
}
