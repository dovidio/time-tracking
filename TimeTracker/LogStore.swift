import Foundation

/// Reads and appends to the log file in the app's Documents directory.
///
/// Writes throw. The caller decides how to surface a failure — a stamp that
/// silently does nothing is the worst possible behaviour for this app.
struct LogStore {
    let url: URL

    init(fileManager: FileManager = .default) {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = documents.appendingPathComponent("taps.log")
        ensureFile(fileManager: fileManager)
    }

    func load() -> [LogEntry] {
        LogParser.parse(text)
    }

    var text: String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    func append(_ line: String) throws {
        guard let data = (line + "\n").data(using: .utf8) else {
            throw LogStoreError.encoding
        }

        ensureFile()

        do {
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            // A descriptor can fail when the file is protected or otherwise
            // unavailable. Rewrite atomically rather than lose the stamp.
            let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            try (existing + line + "\n").write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func ensureFile(fileManager: FileManager = .default) {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        fileManager.createFile(
            atPath: url.path,
            contents: Data(),
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
    }
}

enum LogStoreError: LocalizedError {
    case encoding

    var errorDescription: String? {
        "Could not encode the log line."
    }
}
