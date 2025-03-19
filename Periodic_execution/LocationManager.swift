//
//  LocationManager.swift
//  firebase_test
//
//  Created by 東山友輔 on 2025/01/30.
//

//
//  LocationManager.swift
//  firebase_test
//
//  Created by 東山友輔 on 2025/01/30.
//

import SwiftUI
import CoreLocation
import Foundation

extension Notification.Name {
    static let locationDidUpdate = Notification.Name("locationDidUpdate")
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()
    
    @Published var location: CLLocation? // 現在地情報
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined // 許可状況
   // @Published var isUpdatingLocation: Bool = false // GPS更新中かどうか

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization() // `requestAlwaysAuthorization()` から変更（最初は `whenInUse`）
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
    }
    
    /// 📍 位置情報の取得を開始
    func startUpdatingLocation() {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            DebugLogger.shared.log("🟢 [INFO] 位置情報の更新を開始", level: "INFO")
            manager.startUpdatingLocation()

        } else {
            DebugLogger.shared.log("⚠️ [WARNING] 位置情報の権限が未許可", level: "WARNING")
        }
    }
    
    /// ⏹️ 位置情報の取得を停止
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
        DebugLogger.shared.log("🛑 [INFO] 位置情報の更新を停止", level: "INFO")
    }

    
    /// 🚦 許可状況が変更されたときの処理
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        DebugLogger.shared.log("📌 [INFO] 位置情報の権限変更: \(status.rawValue)", level: "INFO")
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startUpdatingLocation()
        } else {
            DebugLogger.shared.log("⚠️ [WARNING] 位置情報の権限が未許可", level: "WARNING")
        }
    }
    
    //MARK:- 現在位置の座標の更新
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = locations.last {
            DispatchQueue.main.async {
                self.location = newLocation
                DebugLogger.shared.log("📍 [INFO] 位置情報更新: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)", level: "INFO")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DebugLogger.shared.log("🔴 [ERROR] 位置情報の取得に失敗: \(error.localizedDescription)", level: "ERROR")
    }
    

}
