//
//  StackClient.swift
//  stack
//

import Foundation
import Combine
import AppKit

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let displayPath: String
    let isHidden: Bool
}

@MainActor
class StackClient: ObservableObject {
    @Published var appTheme: AppTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "appTheme") ?? "Deep Ocean") ?? .deepOcean {
        didSet { UserDefaults.standard.set(appTheme.rawValue, forKey: "appTheme") }
    }
    
    @Published var outputFileName: String = UserDefaults.standard.string(forKey: "outputFileName") ?? "source_code" {
        didSet { UserDefaults.standard.set(outputFileName, forKey: "outputFileName") }
    }
    
    @Published var downloadFolder: String = UserDefaults.standard.string(forKey: "downloadFolder") ?? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return (home as NSString).appendingPathComponent("Downloads")
    }() {
        didSet { UserDefaults.standard.set(downloadFolder, forKey: "downloadFolder") }
    }
    
    @Published var autoMerge: Bool = UserDefaults.standard.object(forKey: "autoMerge") as? Bool ?? false {
        didSet { UserDefaults.standard.set(autoMerge, forKey: "autoMerge") }
    }
    
    @Published var isWindowMovable: Bool = UserDefaults.standard.bool(forKey: "isWindowMovable") {
        didSet {
            UserDefaults.standard.set(isWindowMovable, forKey: "isWindowMovable")
            NotificationCenter.default.post(name: .windowMovableChanged, object: nil, userInfo: ["value": isWindowMovable])
        }
    }
    
    @Published var menuBarIcon: String = UserDefaults.standard.string(forKey: "menuBarIcon") ?? "doc.on.doc.fill" {
        didSet {
            UserDefaults.standard.set(menuBarIcon, forKey: "menuBarIcon")
            NotificationCenter.default.post(name: .menuBarIconChanged, object: nil, userInfo: ["icon": menuBarIcon])
        }
    }
    
    // Hidden Files Feature
    @Published var includeHiddenFiles: Bool = UserDefaults.standard.object(forKey: "includeHiddenFiles") as? Bool ?? false {
        didSet { UserDefaults.standard.set(includeHiddenFiles, forKey: "includeHiddenFiles") }
    }
    @Published var hasHiddenFiles: Bool = false
    
    // Processing States
    @Published var pendingFiles: [FileItem] = []
    @Published var isProcessing: Bool = false
    @Published var statusText: String = "Ready to merge"
    @Published var progress: Double = 0.0
    @Published var processSuccess: Bool = false
    @Published var resultPath: String? = nil

    private let languageMap: [String: String] = [
        "py": "python", "swift": "swift", "js": "javascript", "mjs": "javascript",
        "cjs": "javascript", "ts": "typescript", "tsx": "tsx", "jsx": "jsx",
        "java": "java", "kt": "kotlin", "kts": "kotlin", "scala": "scala",
        "go": "go", "rs": "rust", "c": "c", "h": "c", "cpp": "cpp", "cc": "cpp",
        "cxx": "cpp", "hpp": "cpp", "hh": "cpp", "cs": "csharp", "php": "php",
        "rb": "ruby", "pl": "perl", "r": "r", "dart": "dart", "lua": "lua",
        "groovy": "groovy", "sh": "bash", "bash": "bash", "zsh": "zsh",
        "ps1": "powershell", "sql": "sql", "html": "html", "htm": "html",
        "css": "css", "scss": "scss", "sass": "sass", "less": "less",
        "xml": "xml", "json": "json", "yaml": "yaml", "yml": "yaml",
        "toml": "toml", "ini": "ini", "cfg": "ini", "md": "markdown",
        "tex": "latex", "dockerfile": "dockerfile", "docker": "dockerfile",
        "makefile": "makefile", "mk": "makefile", "vue": "vue",
        "svelte": "svelte", "graphql": "graphql", "gql": "graphql",
        "proto": "protobuf", "bat": "batch", "cmd": "batch",
        "env": "bash"
    ]

    init() {
        NotificationCenter.default.post(name: .windowMovableChanged, object: nil, userInfo: ["value": isWindowMovable])
    }

    func addPendingItems(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        isProcessing = true
        statusText = "Scanning files..."
        processSuccess = false
        resultPath = nil
        
        Task.detached {
            let newFiles = self.gatherFiles(from: urls)
            
            await MainActor.run {
                let existingURLs = Set(self.pendingFiles.map { $0.url })
                for file in newFiles {
                    if !existingURLs.contains(file.url) {
                        self.pendingFiles.append(file)
                    }
                }
                
                self.updateHiddenState()
                self.isProcessing = false
                
                if self.autoMerge {
                    self.processItems(self.pendingFiles.filter { self.includeHiddenFiles || !$0.isHidden })
                } else {
                    self.updatePendingStatus()
                }
            }
        }
    }
    
    func processItems(_ files: [FileItem]) {
        guard !files.isEmpty else {
            statusText = "No files selected."
            return
        }
        
        isProcessing = true
        progress = 0.0
        statusText = "Merging \(files.count) files..."
        processSuccess = false
        resultPath = nil

        let name = outputFileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "source_code" : outputFileName
        let destination = generateTargetURL(baseName: name)
        
        Task.detached {
            do {
                guard let outputStream = OutputStream(url: destination, append: false) else {
                    throw NSError(domain: "StackError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create output stream"])
                }
                outputStream.open()
                defer { outputStream.close() }

                let totalFiles = Double(files.count)
                
                for (index, file) in files.enumerated() {
                    let language = self.detectLanguage(for: file.url)
                    let content = self.readFileContent(url: file.url)
                    
                    let header = "## \(file.displayPath)\n```\(language)\n"
                    
                    outputStream.write(string: header)
                    outputStream.write(string: content)
                    
                    if !content.hasSuffix("\n") {
                        outputStream.write(string: "\n")
                    }
                    outputStream.write(string: "```\n\n")
                    
                    await MainActor.run {
                        self.progress = Double(index + 1) / totalFiles
                        self.statusText = "Processing: \(file.url.lastPathComponent)"
                    }
                }
                
                outputStream.write(string: "---\n")
                
                await MainActor.run {
                    self.isProcessing = false
                    self.processSuccess = true
                    self.statusText = "Complete"
                    self.resultPath = destination.path
                    self.pendingFiles.removeAll()
                    self.hasHiddenFiles = false
                }
                
            } catch {
                await MainActor.run {
                    self.statusText = "Failed: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - File Operations
    
    nonisolated private func gatherFiles(from urls: [URL]) -> [FileItem] {
        var gathered: [FileItem] = []
        let fm = FileManager.default
        
        for url in urls {
            var isDirectory: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory) else { continue }
            
            let isRootHidden = url.lastPathComponent.hasPrefix(".") || (try? url.resourceValues(forKeys: [.isHiddenKey]))?.isHidden == true
            
            if isDirectory.boolValue {
                let rootName = url.lastPathComponent
                let rootPath = url.standardizedFileURL.path
                
                // Do not skip hidden files during the scan, we will filter them in the UI later
                guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey, .isHiddenKey], options: []) else { continue }
                
                for case let fileURL as URL in enumerator {
                    if let attrs = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .isHiddenKey]), attrs.isRegularFile == true {
                        
                        if !isBinary(url: fileURL) {
                            let filePath = fileURL.standardizedFileURL.path
                            var displayPath = fileURL.lastPathComponent
                            
                            // Construct relative path safely
                            if filePath.hasPrefix(rootPath) {
                                let relative = String(filePath.dropFirst(rootPath.count))
                                let cleanRelative = relative.hasPrefix("/") ? String(relative.dropFirst()) : relative
                                displayPath = rootName + "/" + cleanRelative
                            }
                            
                            // Check if the file or any parent folder is hidden
                            let pathComponents = fileURL.pathComponents.suffix(from: url.pathComponents.count)
                            let isChildHidden = pathComponents.contains(where: { $0.hasPrefix(".") })
                            let hidden = isRootHidden || attrs.isHidden == true || isChildHidden
                            
                            gathered.append(FileItem(url: fileURL, displayPath: displayPath, isHidden: hidden))
                        }
                    }
                }
            } else {
                if !isBinary(url: url) {
                    gathered.append(FileItem(url: url, displayPath: url.lastPathComponent, isHidden: isRootHidden))
                }
            }
        }
        
        return gathered.sorted(by: { $0.displayPath < $1.displayPath })
    }
    
    // Fast binary detection check
    nonisolated private func isBinary(url: URL) -> Bool {
        guard let stream = InputStream(url: url) else { return true }
        stream.open()
        defer { stream.close() }
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = stream.read(&buffer, maxLength: 1024)
        if bytesRead > 0 {
            // Null byte usually indicates binary files (images, executables)
            return buffer.prefix(bytesRead).contains(0)
        }
        return false // Empty files are safe
    }
    
    nonisolated private func detectLanguage(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if !ext.isEmpty, let lang = languageMap[ext] {
            return lang
        }
        
        let name = url.lastPathComponent.lowercased()
        if let lang = languageMap[name] {
            return lang
        }
        
        // If unknown, return empty string so output matches ``` \n
        return ""
    }
    
    nonisolated private func readFileContent(url: URL) -> String {
        if let text = try? String(contentsOf: url, encoding: .utf8) { return text }
        if let text = try? String(contentsOf: url, encoding: .isoLatin1) { return text }
        if let text = try? String(contentsOf: url, encoding: .ascii) { return text }
        return "// [Error: Unable to read file encoding]"
    }
    
    private func generateTargetURL(baseName: String) -> URL {
        let dir = URL(fileURLWithPath: downloadFolder)
        var targetURL = dir.appendingPathComponent("\(baseName).md")
        var counter = 1
        
        while FileManager.default.fileExists(atPath: targetURL.path) {
            targetURL = dir.appendingPathComponent("\(baseName)_\(counter).md")
            counter += 1
        }
        
        return targetURL
    }
    
    func updateHiddenState() {
        hasHiddenFiles = pendingFiles.contains { $0.isHidden }
    }
    
    func updatePendingStatus() {
        processSuccess = false
        let visibleCount = pendingFiles.filter { includeHiddenFiles || !$0.isHidden }.count
        
        if visibleCount == 0 {
            statusText = "Ready to merge"
        } else {
            statusText = "Ready to merge \(visibleCount) item(s)"
        }
    }
    
    func resetState() {
        processSuccess = false
        resultPath = nil
        statusText = "Ready to merge"
        progress = 0.0
    }
}

// Safe multi-thread write
extension OutputStream {
    nonisolated func write(string: String) {
        let data = Data(string.utf8)
        data.withUnsafeBytes { ptr in
            guard let baseAddress = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            var bytesRemaining = data.count
            var totalWritten = 0
            while bytesRemaining > 0 {
                let written = self.write(baseAddress.advanced(by: totalWritten), maxLength: bytesRemaining)
                if written < 0 { break }
                totalWritten += written
                bytesRemaining -= written
            }
        }
    }
}
