//
//  ContentView.swift
//  Periodic_execution
//
//  Created by fukushikyaria2024 on 2025/03/19.
//

import SwiftUI
import MapKit
import Combine

struct ContentView: View {
    @EnvironmentObject var usedata: UserSettings
    @State private var showWebView = false
    @State private var lastUpdate = Date()
    @State private var processingCount = 0
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            // メインコンテンツ
            VStack(spacing: 0) {
                // 上部にWebViewを表示
                VStack {
                    if showWebView {
                        WebViewContainer()
                            .frame(height: UIScreen.main.bounds.height * 0.4)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .shadow(radius: 5)
                    } else {
                        VStack {
                            Image(systemName: "globe")
                                .imageScale(.large)
                                .foregroundStyle(.tint)
                            Text("WebViewを表示するには「WebView表示」ボタンをタップ")
                                .multilineTextAlignment(.center)
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // WebView表示/非表示の切り替えボタン
                    Button(action: {
                        self.showWebView.toggle()
                    }) {
                        Text(showWebView ? "WebView非表示" : "WebView表示")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(showWebView ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Divider().padding(.vertical, 8)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // 位置情報処理の視覚化
                        VStack(alignment: .leading) {
                            Text("🔄 位置情報処理ステータス")
                                .font(.headline)
                            
                            HStack {
                                Text("GPS更新:")
                                    .fontWeight(.medium)
                                Text(usedata.isUpdateGps ? "有効" : "無効")
                                    .foregroundColor(usedata.isUpdateGps ? .green : .red)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Button(action: {
                                    usedata.isUpdateGps.toggle()
                                }) {
                                    Text(usedata.isUpdateGps ? "停止" : "開始")
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(usedata.isUpdateGps ? Color.red : Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            
                            // 最終更新時刻と実行回数
                            HStack {
                                Text("最終更新:")
                                    .fontWeight(.medium)
                                Text("\(formattedTime(date: lastUpdate))")
                                
                                Spacer()
                                
                                Text("実行回数: \(processingCount)")
                                    .fontWeight(.medium)
                            }
                            
                            // 現在位置
                            if let location = usedata.locationManager.location {
                                Text("現在位置: 緯度 \(String(format: "%.6f", location.coordinate.latitude)), 経度 \(String(format: "%.6f", location.coordinate.longitude))")
                                    .font(.caption)
                            } else {
                                Text("現在位置: 取得中...")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(10)
                        
                        // 最も近い動画スポット情報
                        VStack(alignment: .leading) {
                            Text("📍 最も近い動画スポット")
                                .font(.headline)
                            
                            Text("スポット名: \(usedata.closestMovieName_ja)")
                                .fontWeight(.medium)
                            
                            HStack {
                                Text("距離:")
                                    .fontWeight(.medium)
                                Text("\(String(format: "%.2f", usedata.closestDistance)) m")
                                    .foregroundColor(usedata.closestDistance <= 100 ? .green : .red)
                                    .fontWeight(.bold)
                            }
                            
                            Text(usedata.debugMessage)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(10)
                        
                        // マップ表示
                        VStack(alignment: .leading) {
                            Text("🗺 位置情報マップ")
                                .font(.headline)
                            
                            MapView()
                                .frame(height: 200)
                                .cornerRadius(10)
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.05))
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            // 既存のサブスクリプションをキャンセル
            cancellables.forEach { $0.cancel() }
            cancellables.removeAll()
            
            // 定期処理の視覚化用タイマー
            Timer.publish(every: 5.0, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    if usedata.isUpdateGps {
                        self.lastUpdate = Date()
                        self.processingCount += 1
                    }
                }
                .store(in: &cancellables)
        }
        .onDisappear {
            // ビューが非表示になる時にタイマーをキャンセル
            cancellables.forEach { $0.cancel() }
            cancellables.removeAll()
        }
    }
    
    // 日付をフォーマットする関数
    private func formattedTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MapView (地図表示用)
struct MapView: UIViewRepresentable {
    @EnvironmentObject var usedata: UserSettings
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        mapView.setRegion(usedata.region, animated: true)
        
        // 動画スポット用のピンを追加
        addAnnotations(to: mapView)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if let location = usedata.locationManager.location {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
            uiView.setRegion(region, animated: true)
        }
        
        // ピンを更新
        uiView.removeAnnotations(uiView.annotations)
        addAnnotations(to: uiView)
    }
    
    private func addAnnotations(to mapView: MKMapView) {
        for location in usedata.locations {
            if let lat = Double(location.latitude), let lon = Double(location.longitude) {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                annotation.title = location.moviesName_ja
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // ユーザーの現在位置は除外
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "VideoSpot"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // 色を設定
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = .red
                markerView.glyphImage = UIImage(systemName: "video.fill")
            }
            
            return annotationView
        }
    }
}

// MARK: - プレビュー
#Preview {
    // プレビュー用にダミーのUserSettingsを使用
    let previewSettings = UserSettings()
    
    // プレビュー環境では位置情報の更新を行わない
    previewSettings.isUpdateGps = false
    
    return ContentView().environmentObject(previewSettings)
}
