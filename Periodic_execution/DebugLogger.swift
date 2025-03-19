import Foundation

class DebugLogger {
    static let shared = DebugLogger()
    private let fileManager = FileManager.default
    private let logFolder = "DebugLogs"
    private let logFileName = "app_debug_log.txt"

    private init() {
        createLogFileIfNeeded()
    }

    /// 📂 Documentsフォルダのパスを取得
    private func getDocumentsDirectory() -> URL? {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    /// 🌟 **ログフォルダのパスを取得（外部用）**
    func getLogFolderPath() -> URL? {
        return getLogFolder()
    }
    
    /// 📂 DebugLogsフォルダのパスを取得 or 作成
    func getLogFolder() -> URL? {
        guard let documentsPath = getDocumentsDirectory() else { return nil }
        let logFolderPath = documentsPath.appendingPathComponent(logFolder)

        if !fileManager.fileExists(atPath: logFolderPath.path) {
            do {
                try fileManager.createDirectory(at: logFolderPath, withIntermediateDirectories: true)
            } catch {
                print("❌ ログフォルダの作成に失敗: \(error)")
                return nil
            }
        }
        return logFolderPath
    }

    /// 📝 ログファイルのパスを取得
    private func getLogFilePath() -> URL? {
        guard let logFolderPath = getLogFolder() else { return nil }
        return logFolderPath.appendingPathComponent(logFileName)
    }

    /// 📝 ログファイルを作成（存在しない場合）
    private func createLogFileIfNeeded() {
        guard let logFilePath = getLogFilePath() else { return }
        
        if !fileManager.fileExists(atPath: logFilePath.path) {
            do {
                try "".write(to: logFilePath, atomically: true, encoding: .utf8)
                print("✅ ログファイルを作成: \(logFilePath)")
            } catch {
                print("❌ ログファイルの作成に失敗: \(error)")
            }
        }
    }

    /// 📝 ログを追加（日時つき、追記形式）
    func log(_ message: String, level: String = "INFO") {
        guard let logFilePath = getLogFilePath() else { return }
        
        let timestamp = getCurrentTimestamp()
        let logMessage = "\(timestamp) [\(level)] \(message)\n"

        if let data = logMessage.data(using: .utf8) {
            if fileManager.fileExists(atPath: logFilePath.path) {
                // 追記モードで書き込む
                do {
                    let fileHandle = try FileHandle(forWritingTo: logFilePath)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                } catch {
                    print("❌ ログの書き込みに失敗: \(error)")
                }
            } else {
                // 新規作成
                do {
                    try data.write(to: logFilePath)
                } catch {
                    print("❌ 新しいログファイルの作成に失敗: \(error)")
                }
            }
        }
    }

    /// 📜 ログファイルの内容を取得
    func fetchLogs() -> String? {
        guard let logFilePath = getLogFilePath() else { return nil }

        do {
            return try String(contentsOf: logFilePath, encoding: .utf8)
        } catch {
            print("❌ ログの取得に失敗: \(error)")
            return nil
        }
    }

    /// 🗑️ ログファイルを削除
    func clearLogs() {
        guard let logFilePath = getLogFilePath() else { return }

        do {
            try fileManager.removeItem(at: logFilePath)
            createLogFileIfNeeded() // 再作成
            print("🗑️ ログファイルを削除しました")
        } catch {
            print("❌ ログの削除に失敗: \(error)")
        }
    }

    /// ⏰ 現在のタイムスタンプを取得（YYYY年_MM月DD日 HH:mm:ss の形式）
    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年_MM月dd日 HH:mm:ss"
        formatter.locale = Locale(identifier: "ja_JP") // 日本のロケールを設定
        return formatter.string(from: Date())
    }
}
