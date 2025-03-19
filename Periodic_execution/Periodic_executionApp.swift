//
//  Periodic_executionApp.swift
//  Periodic_execution
//
//  Created by fukushikyaria2024 on 2025/03/19.
//

import SwiftUI

@main
struct Periodic_executionApp: App {
    // ✅ `UserSettings` をアプリ全体で管理
    @StateObject var userSettings = UserSettings()
    
    // ✅ アプリのライフサイクル（フォアグラウンド・バックグラウンドなど）を監視
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings) // ✅ アプリ全体に `UserSettings` を共有
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .background:
                print("🔴 [INFO] アプリがバックグラウンドに入りました。データを保存します")
                userSettings.saveLocationsToUserDefaults() // アプリ終了時に UserDefaults へ保存
            case .inactive:
                print("🟡 [INFO] アプリが非アクティブになりました")
            case .active:
                print("🟢 [INFO] アプリがアクティブになりました")
            @unknown default:
                break
            }
        }
    }
}
