import Foundation

class FileManagerHelper: ObservableObject {
    static let shared = FileManagerHelper()
    private let fileManager = FileManager.default

    @Published var currentFiles: [String] = [] // 現在表示しているフォルダ内のファイル・フォルダ一覧
    @Published var currentFolderPath: URL? // 現在のフォルダのパス
    private let movieFolder = "MoviesStory"
    

    private init() {
        fetchAppFiles()
    }

    /// 📂 Documentsフォルダのパスを取得
    func getDocumentsDirectory() -> URL? {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    /// 📂 MyAppDataフォルダのパスを取得 or 作成
    func getAppFolder() -> URL? {
        guard let documentsPath = getDocumentsDirectory() else { return nil }
        let appFolderPath = documentsPath.appendingPathComponent(movieFolder)

        if !fileManager.fileExists(atPath: appFolderPath.path) {
            try? fileManager.createDirectory(at: appFolderPath, withIntermediateDirectories: true)
        }
        return appFolderPath
    }



    /// 📜 MyAppDataフォルダ内のファイル・フォルダ一覧を取得
    func fetchAppFiles() {
        guard let appFolderPath = getAppFolder() else { return }
        fetchFiles(in: appFolderPath)
    }

    /// 📜 指定したフォルダの中のファイル・フォルダ一覧を取得
    func fetchFiles(in folderPath: URL) {
        do {
            let items = try fileManager.contentsOfDirectory(at: folderPath, includingPropertiesForKeys: nil)
            let sortedItems = items.map { $0.lastPathComponent }
            DispatchQueue.main.async {
                self.currentFolderPath = folderPath
                self.currentFiles = sortedItems
            }
        } catch {
            print("❌ ファイル一覧取得失敗: \(error)")
        }
    }

    /// 📂 指定したパスがフォルダかどうかを判定
    func isDirectory(at path: URL) -> Bool {
        var isDir: ObjCBool = false
        return fileManager.fileExists(atPath: path.path, isDirectory: &isDir) && isDir.boolValue
    }
    /// 🔄 指定したファイルを MyAppData フォルダへコピー
    func copyFileToAppFolder(fileName: String) {
        guard let documentsPath = getDocumentsDirectory(),
              let appFolderPath = getAppFolder() else {
            print("❌ フォルダの取得に失敗")
            return
        }

        let sourceURL = documentsPath.appendingPathComponent(fileName)
        let destinationURL = appFolderPath.appendingPathComponent(fileName)

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("✅ \(fileName) を MyAppData にコピー成功")
            fetchAppFiles()
        } catch {
            print("❌ ファイルコピー失敗: \(error)")
        }
    }

    /// 🗑️ 指定したファイルまたはフォルダを削除
    func deleteItem(at path: URL) {
        do {
            try fileManager.removeItem(at: path)
            print("🗑️ \(path.lastPathComponent) を削除しました")
            if let folderPath = currentFolderPath {
                fetchFiles(in: folderPath) // 現在のフォルダを再読み込み
            } else {
                fetchAppFiles()
            }
        } catch {
            print("❌ 削除失敗: \(error)")
        }
    }
}
