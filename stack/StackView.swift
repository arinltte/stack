//
//  StackView.swift
//  stack
//

import SwiftUI
import UniformTypeIdentifiers

struct StackView: View {
    @StateObject var client = StackClient()
    var onClose: () -> Void

    @State private var showSettings: Bool = false
    @State private var showAbout: Bool = false
    @State private var isHoveringDropZone: Bool = false
    
    @State private var updateStatus: String = "Check for Updates"
    @State private var updateURL: String? = nil
    
    private let baseWindowWidth: CGFloat = 380
    
    private var visibleFiles: [FileItem] {
        client.pendingFiles.filter { client.includeHiddenFiles || !$0.isHidden }
    }
    
    // Smoothly and dynamically adjust the window based on exactly how many files are dropped
        private var dynamicWindowHeight: CGFloat {
            if showAbout { return 400 }
            if showSettings { return 300 }
            
            // Base logic on ALL pending files (including hidden ones) so the UI doesn't collapse
            if !client.pendingFiles.isEmpty && !client.isProcessing && !client.processSuccess {
                // At least 1 row height to show the "No visible files" placeholder
                let rowCount = max(min(visibleFiles.count, 4), 1)
                
                // Changed base height to 270, and row multiplier to 36
                var height = 270 + CGFloat(rowCount * 36)
                if client.hasHiddenFiles { height += 28 } // Space for the hidden files toggle
                return height
            }
            return 280
        }

    var body: some View {
        VStack(spacing: 0) {
            if showSettings {
                if showAbout {
                    aboutContent
                } else {
                    settingsContent
                }
            } else {
                mainContent
            }

            Spacer(minLength: 0)

            Divider().opacity(0.5)
            if showAbout {
                backOnlyBottomBar
            } else {
                bottomBar
            }
        }
        .frame(width: baseWindowWidth, height: dynamicWindowHeight)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: dynamicWindowHeight)
        .animation(.easeInOut(duration: 0.2), value: showSettings)
        .animation(.easeInOut(duration: 0.2), value: showAbout)
        .tint(client.appTheme.accentColor)
        .background(AmbientThemeBackground(theme: client.appTheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 12) {
            Text("Stack Codebase")
                .font(.system(size: 14, weight: .semibold))
                .padding(.top, 14)
            
            // Drop Zone
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundColor(isHoveringDropZone ? client.appTheme.accentColor : .secondary.opacity(0.4))
                    .background(isHoveringDropZone ? client.appTheme.accentColor.opacity(0.15) : Color.black.opacity(0.1))
                
                VStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 26, weight: .light))
                        .foregroundColor(isHoveringDropZone ? client.appTheme.accentColor : .secondary)
                    
                    Text("Drag & Drop Folders or Files")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .frame(height: 100)
            .padding(.horizontal, 16)
            .onDrop(of: [.fileURL], isTargeted: $isHoveringDropZone) { providers in
                handleDrop(providers: providers)
                return true
            }
            .onTapGesture {
                browseFiles()
            }
            
            // File List & Actions (Evaluates on pendingFiles to prevent UI collapse on pure hidden files)
            if !client.pendingFiles.isEmpty && !client.isProcessing && !client.processSuccess {
                
                VStack(spacing: 6) {
                    // Header with Clear Button
                    HStack {
                        Text("Pending Files (\(visibleFiles.count))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: {
                            client.pendingFiles.removeAll()
                            client.updateHiddenState()
                            client.updatePendingStatus()
                        }) {
                            Text("Clear")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(client.appTheme.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18)
                    
                    // Pending List
                                        if visibleFiles.isEmpty {
                                            Text("No visible files. Enable hidden files below.")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .center)
                                                .frame(height: 36) // Match a single row height
                                        } else {
                                            ScrollView {
                                                VStack(spacing: 4) {
                                                    ForEach(visibleFiles, id: \.id) { file in
                                                        // ... your HStack for the file row ...
                                                        HStack(spacing: 8) {
                                                            Image(systemName: "doc.text.fill")
                                                                .font(.system(size: 11))
                                                                .foregroundColor(.secondary)
                                                            
                                                            Text(file.displayPath)
                                                                .font(.system(size: 11))
                                                                .lineLimit(1)
                                                                .truncationMode(.middle)
                                                            
                                                            Spacer()
                                                            
                                                            Button {
                                                                client.pendingFiles.removeAll { $0.id == file.id }
                                                                client.updateHiddenState()
                                                                client.updatePendingStatus()
                                                            } label: {
                                                                Image(systemName: "xmark.circle.fill")
                                                                    .font(.system(size: 11))
                                                                    .foregroundColor(.secondary.opacity(0.8))
                                                            }
                                                            .buttonStyle(.plain)
                                                        }
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6) // This creates a ~28px tall row
                                                        .background(Color.black.opacity(0.12))
                                                        .cornerRadius(6)
                                                    }
                                                }
                                                .padding(.horizontal, 16)
                                                // Remove bottom padding from VStack to prevent drifting
                                            }
                                            // REPLACE .frame(maxHeight: 124) WITH THIS:
                                            .frame(height: CGFloat(max(min(visibleFiles.count, 4), 1)) * 36)
                                        }
                    
                    // Include Hidden Files Toggle
                    if client.hasHiddenFiles {
                        Toggle("Include hidden files", isOn: Binding(
                            get: { client.includeHiddenFiles },
                            set: { val in
                                client.includeHiddenFiles = val
                                client.updatePendingStatus()
                            }
                        ))
                        .font(.system(size: 11))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 2)
                    }
                    
                    // Merge Action
                    Button(action: {
                        client.processItems(visibleFiles)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down.on.square.fill")
                                .font(.system(size: 12))
                            Text("Merge \(visibleFiles.count) Item(s)")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(visibleFiles.isEmpty ? Color.gray.opacity(0.5) : client.appTheme.accentColor)
                        .foregroundColor(visibleFiles.isEmpty ? .secondary : .white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(visibleFiles.isEmpty) // Prevent merge if strictly 0 files are active
                    .padding(.horizontal, 16)
                }
            }

            // Status Progress Bar
            if client.isProcessing || client.processSuccess || client.pendingFiles.isEmpty {
                VStack(spacing: 4) {
                    if client.isProcessing {
                        ProgressView(value: client.progress)
                            .progressViewStyle(.linear)
                            .frame(height: 4)
                            .padding(.horizontal, 16)
                        
                        Text(client.statusText)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else if client.processSuccess {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                            Text("Saved: \(URL(fileURLWithPath: client.resultPath ?? "").lastPathComponent)")
                                .font(.system(size: 11, weight: .medium))
                        }
                        Button("Reveal in Finder") {
                            if let path = client.resultPath {
                                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                            }
                            client.resetState()
                        }
                        .font(.system(size: 10))
                        .buttonStyle(.plain)
                        .foregroundColor(client.appTheme.accentColor)
                    } else {
                        Text(client.statusText)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 32)
            }
            
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Actions
    
    private func handleDrop(providers: [NSItemProvider]) {
        let group = DispatchGroup()
        var urls: [URL] = []
        
        for provider in providers {
            // Using loadDataRepresentation completely avoids the macOS SwiftUI `kDragIPCCompleted` reentrancy warnings
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                group.enter()
                provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
                    defer { group.leave() }
                    if let data = data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            urls.append(url)
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            client.addPendingItems(urls)
        }
    }
    
    private func browseFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        
        if panel.runModal() == .OK {
            client.addPendingItems(panel.urls)
        }
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) { showSettings.toggle() }
            }) {
                Image(systemName: showSettings ? "chevron.left" : "gearshape")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Exit") { NSApplication.shared.terminate(nil) }
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .buttonStyle(.plain)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(height: 28)
    }

    private var backOnlyBottomBar: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) { if showAbout { showAbout = false } }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(height: 28)
    }

    // MARK: - Settings Content
    
    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Settings")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: { withAnimation { showAbout = true } }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Default Save Location")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                HStack {
                    Text(client.downloadFolder)
                        .font(.system(size: 11, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Choose") { chooseDownloadFolder() }
                        .font(.system(size: 10))
                        .controlSize(.small)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Output File Name")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    TextField("source_code", text: $client.outputFileName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                    Text(".md")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider().opacity(0.5).padding(.vertical, 4)
            
            Toggle("Auto-merge on drop (Skip Review)", isOn: $client.autoMerge)
                .font(.system(size: 12))
            
            Toggle("Allow Window Dragging", isOn: $client.isWindowMovable)
                .font(.system(size: 12))
            
            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private func chooseDownloadFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: client.downloadFolder)

        if panel.runModal() == .OK, let url = panel.urls.first {
            client.downloadFolder = url.path
        }
    }

    // MARK: - About Content
    
    private var aboutContent: some View {
        VStack(spacing: 12) {
            Text("About")
                .font(.system(size: 14, weight: .semibold))

            VStack(spacing: 3) {
                if let nsImage = NSImage(named: "AppIcon") {
                    Image(nsImage: nsImage)
                        .resizable()
                        .frame(width: 56, height: 56)
                        .cornerRadius(12)
                }
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Stack")
                    .font(.system(size: 13, weight: .bold))
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                if let url = updateURL {
                    NSWorkspace.shared.open(URL(string: url)!)
                    return
                }
                updateStatus = "Checking..."
                Task {
                    do {
                        let reqURL = URL(string: "https://github.com/arinltte/stack/releases/latest")!
                        var request = URLRequest(url: reqURL)
                        request.httpMethod = "HEAD"
                        let (_, response) = try await URLSession.shared.data(for: request)
                        let tag = (response.url?.lastPathComponent ?? "")
                            .trimmingCharacters(in: .whitespaces)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "v"))

                        let current = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0.1.0"
                        let isNewer = tag.compare(current, options: .numeric) == .orderedDescending

                        if !tag.isEmpty && isNewer {
                            updateStatus = "New Version Released (v\(tag))"
                            updateURL = "https://github.com/arinltte/stack/releases/latest"
                        } else {
                            updateStatus = "Up to Date"
                        }
                    } catch {
                        updateStatus = "Check for Updates"
                    }
                }
            }) {
                Text(updateStatus)
                    .font(.system(size: 11))
                    .foregroundColor(updateURL != nil ? .white : nil)
                    .padding(.horizontal, updateURL != nil ? 8 : 0)
                    .padding(.vertical, updateURL != nil ? 3 : 0)
                    .background(updateURL != nil ? client.appTheme.accentColor : Color.clear)
                    .cornerRadius(4)
            }
            .controlSize(.small)
            .disabled(updateStatus == "Checking..." || updateStatus == "Up to Date")

            Text("Stack merges your codebase into a single Markdown document, ready for review or LLM prompting.")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            Divider().opacity(0.5)

            HStack {
                Text("Menu Bar Icon")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("", selection: $client.menuBarIcon) {
                    Text("📄 Stack").tag("doc.on.doc.fill")
                    Text("⬇ Arrow").tag("arrow.down.circle.fill")
                    Text("📦 Box").tag("shippingbox.fill")
                    Text("🔨 Hammer").tag("hammer.fill")
                    Text("🔗 Link").tag("link")
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            
            HStack {
                Text("Theme")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Picker("", selection: $client.appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Spacer(minLength: 0)

            VStack(spacing: 1) {
                Text("Developed by [arinltte](https://github.com/arinltte)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .tint(client.appTheme.accentColor)

                Text("cjshen00@gmail.com")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .padding(14)
    }
}
