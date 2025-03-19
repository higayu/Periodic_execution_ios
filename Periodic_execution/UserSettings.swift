//
//  UserSettings.swift
//  Periodic_execution
//
//  Created by fukushikyaria2024 on 2025/03/19.
//


import SwiftUI
import Combine
import MapKit
import CoreLocation

// UserDefaults用のプロパティラッパーを追加
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

// ✅ Identifiable に準拠
enum Page: Identifiable {
    case home
    case sidebar

    var id: Self { self } // 各ケースを一意に識別
}

class UserSettings: ObservableObject {
    // UserDefaultsのキー
    private enum Keys {
        static let selectLang = "select_lang"
        static let isUpdateGps = "is_update_gps"
        static let fakeMode = "fake_mode"
    }
    
    @Published var locationManager:LocationManager!
    
    @Published var select_lang: String {
        didSet {
            UserDefaults.standard.set(select_lang, forKey: Keys.selectLang)
            UserDefaults.standard.synchronize()
        }
    }
    
    @Published var isUpdateGps: Bool {
        didSet {
            UserDefaults.standard.set(isUpdateGps, forKey: Keys.isUpdateGps)
            UserDefaults.standard.synchronize()
            print("🔄 isUpdateGps saved to UserDefaults: \(isUpdateGps)")
        }
    }
    
    @Published var FakeMode: Bool {
        didSet {
            UserDefaults.standard.set(FakeMode, forKey: Keys.fakeMode)
            UserDefaults.standard.synchronize()
            print("🔄 FakeMode saved to UserDefaults: \(FakeMode)")
        }
    }

    @Published var username: String = "ゲスト"
    @Published var isSignedIn = false
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var profileImage: UIImage? = nil
    @Published var idToken: String = ""
    @Published var accessToken: String = ""

    @Published var receivedMessage: String = "No message yet"
    @Published var serverMessage: String = ""
    @Published var errorMessage: String = ""
    
    @Published var initialUrl = "https://carptaxi-miyajima-41cdd.web.app"
    
    @Published var navigateToWebView = false
    @Published var shouldReload: Bool = false // ✅ 追加

    
    @Published var closestMovieName_ja: String = "計算中..."
    @Published var closestMovieName_en: String = "計算中..."
    @Published var closestDistance: Double = 0.0
    @Published var debugMessage: String = "📂 ファイルを選択してください" // 🛠 デバッグ用メッセージ
    @Published var isVideoPlayerPresented = false
    @Published var selectedVideoURL: URL?
    
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.2959, longitude: 132.3197),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @Published var proximityTimer: Timer?
    
    @Published var matchingIndex: Int?
    @Published var lastToastTime: Date?
    @Published var showToast: Bool = false
    

    @Published var locations: [(latitude: String,longitude: String,data_id:Int, moviesName_ja: String, moviesName_en: String, radius: String, description_ja: String, description_en: String,looked_flg : Bool)] = []


    @Published var appFolderPath: URL?
    
    
    @Published var DebugLog:URL?
    
    @Published var isCookieSet = false
    
 
    
    //MARK: - ページの情報
    @Published var currentPage: Page? = .home // 初期値を SelectLang にする

    //MARK: - 開発環境フラグとログアウトボタンの使用可能フラグ
    // Firestore の dev_flg ドキュメントのフィールドを保持するプロパティ
    @Published var pageFlg: Bool = false
    @Published var test_spot_flg: Bool = false
    @Published var logoutFlg: Bool = false

    //MARK: - 初期処理
    func fetchAppFolderPath() {
        self.appFolderPath = FileManagerHelper.shared.getAppFolder()
        self.DebugLog = DebugLogger.shared.getLogFolderPath() // 修正
    }

    
    init() {
        // Initialize properties that need to be set before didSet is triggered
        self.select_lang = UserDefaults.standard.string(forKey: Keys.selectLang) ?? "ja" // Default to Japanese
        self.FakeMode = UserDefaults.standard.bool(forKey: Keys.fakeMode)
        self.locationManager = LocationManager()
        
        // UserDefaultsから初期値を読み込む
        let defaults = UserDefaults.standard
        self.isUpdateGps = defaults.bool(forKey: Keys.isUpdateGps)
    }

    



    //MARK: - getVIdeoURL
    func getVideoURL(fileName: String) -> URL? {
        guard let appFolderPath = appFolderPath else {
            self.debugMessage = "❌ `MyAppData` フォルダの取得に失敗"
            return nil
        }
        
        let videoFileName = fileName
        print("¥n"+videoFileName)
        let videoURL = appFolderPath.appendingPathComponent(videoFileName)
        print(videoURL)
        if FileManager.default.fileExists(atPath: videoURL.path) {
            self.debugMessage = "✅ `\(videoFileName)` は存在します"
            return videoURL
        } else {
            self.debugMessage = "❌ `\(videoFileName)` が見つかりません"
            return nil
        }
    }
    
    // MARK: - 指定した ID までの要素が全て視聴済みか判定する関数
    func areAllMoviesLookedUpTo(maxId: Int) -> Bool {
        return self.locations
            .filter { $0.data_id <= maxId } // 指定したID以下の要素を取得
            .allSatisfy { $0.looked_flg } // 全ての要素のlooked_flgがtrueかチェック
    }
    
    //MARK: -📌 指定したインデックスの座標を更新（moviesName を保持）
    func updateLocation(at index: Int, latitude: String, longitude: String, data_id: Int, radius: String, description_ja: String, description_en: String) {
        if index >= 0 && index < self.locations.count {
            let currentName_ja = self.locations[index].moviesName_ja  // moviesName を保持
            let currentName_en = self.locations[index].moviesName_en  // moviesName を保持
            self.locations[index] = (latitude, longitude, data_id, currentName_ja, currentName_en, radius, description_ja, description_en, false)
        }
    }
    
    //MARK: - 近くにある動画の取得
    func getClosestLocation() {
            guard let currentLocation =  self.locationManager.location else { return }

            var closestLocation: CLLocation?
            var closestName_ja: String = "なし"
            var closestName_en: String = "なし"
            var minDistance: Double = Double.greatestFiniteMagnitude
            var closestRadius: Double = 100 // デフォルト値
            var closestIndex: Int?

            for (index, coordinate) in self.locations.enumerated() {
                if let latitude = Double(coordinate.latitude),
                   let longitude = Double(coordinate.longitude),
                   let radius = Double(coordinate.radius) {
                    let location = CLLocation(latitude: latitude, longitude: longitude)
                    let distance = currentLocation.distance(from: location)

                    if distance < minDistance {
                        minDistance = distance
                        closestLocation = location
                        closestName_ja = coordinate.moviesName_ja
                        closestName_en = coordinate.moviesName_en
                        closestRadius = radius
                        closestIndex = index
                    }
                }
            }

            if let index = closestIndex, let _ = closestLocation {
                let closestCoordinate = self.locations[index]
                
                
                closestMovieName_ja = closestName_ja
                closestMovieName_en = closestName_en
                closestDistance = minDistance

                if minDistance <= closestRadius {
                    lastToastTime = Date()
                    
                    // ✅ 日本語動画のみを使用するため、不要な `closestMovieName` の定義を削除
                    // let closestMovieName: String = self.select_lang == "ja" ? closestMovieName_ja : closestMovieName_en
                    let closestMovieName: String = closestMovieName_ja
                    
                        // 既に視聴済みかチェック
                        if closestCoordinate.looked_flg {
                            debugMessage = "✅ 既に視聴済みのためスキップ: \(closestName_ja)"
                            print(debugMessage)
                            return
                        }
                    
                    // 追加: 再生条件を満たすかチェック
                    if closestCoordinate.data_id != 1 && !self.areAllMoviesLookedUpTo(maxId: closestCoordinate.data_id - 1) {
                        debugMessage = "❌ 前の動画が未視聴のためスキップ: \(closestName_ja)"
                        print(debugMessage)
                        return
                    }
                    
                    if let videoURL = getVideoURL(fileName: closestMovieName) {
                        debugMessage = "✅ 動画が見つかりました: \(closestMovieName_ja)"
                        print(debugMessage)
                        selectedVideoURL = videoURL
                        isVideoPlayerPresented = true
                        //firebaseに視聴したフラグを更新処理
                        
                        // ✅ 動画視聴確定時に `looked_flg` を `true` に更新
                        self.locations[index].looked_flg = true
                        
                                  
                    } else {
                        debugMessage = "❌ 動画が見つかりません: \(closestMovieName_ja)"
                        print(debugMessage)
                        showToast = true
                    }
                } else {
                    debugMessage = "📍 まだ目的地まで遠い（距離: \(String(format: "%.2f", minDistance)) m, 許容範囲: \(String(format: "%.2f", closestRadius)) m）"
                }
            }
        }
    

    // MARK: - locations を UserDefaults に保存
    func saveLocationsToUserDefaults() {
        DispatchQueue.main.async {
            let defaults = UserDefaults.standard
            let locationDictArray = self.locations.map { location in
                return [
                    "latitude": location.latitude,
                    "longitude": location.longitude,
                    "data_id": location.data_id,
                    "moviesName_ja": location.moviesName_ja,
                    "moviesName_en": location.moviesName_en,
                    "radius": location.radius,
                    "description_ja": location.description_ja,
                    "description_en": location.description_en,
                    "looked_flg": location.looked_flg
                ] as [String: Any]
            }
            defaults.setValue(locationDictArray, forKey: "locations")
            DebugLogger.shared.log("🟢 [DEBUG] locations を保存しました（件数: \(self.locations.count)）", level: "DEBUG")
        }
    }

    // MARK: - locations を UserDefaults から復元
    func loadLocationsFromUserDefaults() {
        DispatchQueue.main.async {
            let defaults = UserDefaults.standard
            if let savedLocations = defaults.array(forKey: "locations") as? [[String: Any]] {
                self.locations = savedLocations.compactMap { dict in
                    guard let latitude = dict["latitude"] as? String,
                          let longitude = dict["longitude"] as? String,
                          let data_id = dict["data_id"] as? Int,
                          let moviesName_ja = dict["moviesName_ja"] as? String,
                          let moviesName_en = dict["moviesName_en"] as? String,
                          let radius = dict["radius"] as? String,
                          let description_ja = dict["description_ja"] as? String,
                          let description_en = dict["description_en"] as? String,
                          let looked_flg = dict["looked_flg"] as? Bool else {
                        return nil
                    }
                    return (latitude: latitude, longitude: longitude, data_id: data_id, moviesName_ja: moviesName_ja, moviesName_en: moviesName_en, radius: radius, description_ja: description_ja, description_en: description_en, looked_flg: looked_flg)
                }
                DebugLogger.shared.log("🔵 [DEBUG] locations を復元しました（件数: \(self.locations.count)）", level: "DEBUG")
            } else {
                DebugLogger.shared.log("⚠️ [WARNING] locations の復元に失敗。データなし", level: "WARNING")
            }
        }
    }

    // MARK: - アプリ終了時にデータを保存
    func saveDataOnAppClose() {
        saveLocationsToUserDefaults()
    }

    // MARK: - セッション情報を保存
    func saveSession() {
        DispatchQueue.main.async {
            let defaults = UserDefaults.standard
            print("🟢 [DEBUG] セッション保存開始")
            
            // 基本情報の保存
            defaults.set(self.userName, forKey: "userName")
            defaults.set(self.userEmail, forKey: "userEmail")
            defaults.set(self.idToken, forKey: "idToken")
            defaults.set(self.accessToken, forKey: "accessToken")
            defaults.set(self.isSignedIn, forKey: "isSignedIn")
            
            // 設定値の保存
            defaults.set(self.isUpdateGps, forKey: Keys.isUpdateGps)
            defaults.set(self.FakeMode, forKey: Keys.fakeMode)
            defaults.set(self.select_lang, forKey: Keys.selectLang)
            
            // フラグの保存
            defaults.set(self.pageFlg, forKey: "pageFlg")
            defaults.set(self.logoutFlg, forKey: "logoutFlg")
            
            // 変更を確実に保存
            defaults.synchronize()
            
            print("   - isUpdateGps: \(self.isUpdateGps)")
            print("   - FakeMode: \(self.FakeMode)")
            print("   - select_lang: \(self.select_lang)")
            print("🟢 [DEBUG] セッション保存完了")
        }
    }

    // MARK: - セッション情報を復元
    func loadSession() {
        DispatchQueue.main.async {
            let defaults = UserDefaults.standard
            print("🔵 [DEBUG] セッション復元開始")
            
            // 基本情報の復元
            self.isSignedIn = defaults.bool(forKey: "isSignedIn")
            self.userName = defaults.string(forKey: "userName") ?? "ゲスト"
            self.userEmail = defaults.string(forKey: "userEmail") ?? ""
            self.idToken = defaults.string(forKey: "idToken") ?? ""
            self.accessToken = defaults.string(forKey: "accessToken") ?? ""
            
            // 設定値の復元
            self.isUpdateGps = defaults.bool(forKey: Keys.isUpdateGps)
            self.FakeMode = defaults.bool(forKey: Keys.fakeMode)
            self.select_lang = defaults.string(forKey: Keys.selectLang) ?? ""
            
            // フラグの復元
            self.pageFlg = defaults.bool(forKey: "pageFlg")
            self.logoutFlg = defaults.bool(forKey: "logoutFlg")
            
            print("   - isUpdateGps: \(self.isUpdateGps)")
            print("   - FakeMode: \(self.FakeMode)")
            print("   - select_lang: \(self.select_lang)")
            print("🔵 [DEBUG] セッション復元完了")
        }
    }

 
    // 位置情報が更新されたときにregionを更新するメソッドを追加
    func updateRegionFromCurrentLocation() {
        if let location = locationManager.location {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }

}
