import SwiftUI
import WebKit
import MapKit
import CoreLocation

//MARK: - WebViewの定義
struct WebView: UIViewRepresentable {
    @EnvironmentObject var usedata: UserSettings
    static let sharedProcessPool = WKProcessPool()

    //MARK: - makeUIView
    func makeUIView(context: Context) -> WKWebView {
        DebugLogger.shared.log("📂 WebView を作成開始", level: "INFO")

        let webViewConfiguration = WKWebViewConfiguration()
        // JavaScript の有効化設定 (iOS 14以降対応)
        if #available(iOS 14.0, *) {
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = true
            webViewConfiguration.defaultWebpagePreferences = preferences
        } else {
            webViewConfiguration.preferences.javaScriptEnabled = true
        }
        
        webViewConfiguration.processPool = WKProcessPool()
        webViewConfiguration.websiteDataStore = WKWebsiteDataStore.default()

        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.configuration.userContentController.add(context.coordinator, name: "messageHandler")

        // ピンチイン・アウトを無効化
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        if let gestures = webView.scrollView.gestureRecognizers {
            gestures.forEach { gesture in
                if gesture is UIPinchGestureRecognizer {
                    gesture.isEnabled = false
                }
            }
        }

        DebugLogger.shared.log("✅ WebView を作成しました", level: "INFO")

        DispatchQueue.main.async {
            self.setCookie(for: webView) {
                DebugLogger.shared.log("✅ クッキー設定完了", level: "INFO")
            }
        }

        DispatchQueue.main.async {
            self.loadWebView(webView)
        }

        return webView
    }

    //MARK: - キャッシュクリア
    func clearCache() {
        DebugLogger.shared.log("🗑 WebView のキャッシュ削除を開始", level: "INFO")

        let websiteDataTypes: Set<String> = [
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeWebSQLDatabases,
            WKWebsiteDataTypeFetchCache,
            WKWebsiteDataTypeDiskCache,
        ]

        let dateFrom = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom) {
            DebugLogger.shared.log("✅ WebView のキャッシュが削除されました", level: "INFO")
        }
    }

    //MARK: - setCookie

    private func setCookie(for webView: WKWebView, completion: @escaping () -> Void) {
        guard !usedata.isCookieSet else {
            DebugLogger.shared.log("⚠️ クッキーは既に設定済みのためスキップ", level: "INFO")
            completion()
            return
        }

        DispatchQueue.main.async {
            guard let url = URL(string: usedata.initialUrl) else {
                DebugLogger.shared.log("❌ クッキー設定失敗: 無効な URL", level: "ERROR")
                return
            }

            let domain = url.host ?? "carptaxi-miyajima.web.app"
            let cookieProperties: [HTTPCookiePropertyKey: Any] = [
                .domain: domain,
                .path: "/",
                .name: "idToken",
                .value: self.usedata.idToken,
                .secure: true,
                .expires: Date().addingTimeInterval(3600),
                .sameSitePolicy: "None"
            ]

            if let cookie = HTTPCookie(properties: cookieProperties) {
                let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
                cookieStore.setCookie(cookie) {
                    DebugLogger.shared.log("✅ クッキー設定成功: \(cookie)", level: "INFO")
                    usedata.isCookieSet = true // クッキー設定済みフラグを true にする
                    completion()
                }
            } else {
                DebugLogger.shared.log("❌ クッキーの作成に失敗", level: "ERROR")
                completion()
            }
        }
    }


    //MARK: - ロード
    private func loadWebView(_ webView: WKWebView) {
        DispatchQueue.main.async {
            guard let url = URL(string: usedata.initialUrl) else {
                DebugLogger.shared.log("❌ WebView のロード失敗: 無効な URL", level: "ERROR")
                return
            }
            let request = URLRequest(url: url)
            webView.load(request)
            DebugLogger.shared.log("✅ WebView をロード: \(usedata.initialUrl)", level: "INFO")
        }
    }

    //MARK: - アップデート
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let jsCommand = """
        document.cookie = 'idToken=\(usedata.idToken); path=/; Secure; SameSite=None';
        console.log('✅ idTokenクッキーがセットされました: ' + document.cookie);
        """
        
        uiView.evaluateJavaScript(jsCommand) { _, error in
            if let error = error {
                DebugLogger.shared.log("❌ JavaScript 実行失敗: \(error.localizedDescription)", level: "ERROR")
            } else {
                DebugLogger.shared.log("✅ JavaScript によるクッキー設定成功", level: "INFO")
            }
        }
    }


    //MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "messageHandler", let body = message.body as? String {
                DebugLogger.shared.log("📩 WebView からメッセージ受信: \(body)", level: "INFO")
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
}

// MARK: - SwiftUI Wrapper (WebViewContainer)
struct WebViewContainer: View {
    @EnvironmentObject var usedata: UserSettings
    public var webView = WebView()
    @State private var proximityTimer: Timer? // タイマー管理用の State 変数

    var body: some View {
        self.webView
            .edgesIgnoringSafeArea(.all)
            .fullScreenCover(isPresented: $usedata.isVideoPlayerPresented) {
                if let videoURL = usedata.selectedVideoURL {
                    VideoPlayerView(videoURL: videoURL)
                } else {
                    Text("動画が見つかりませんでした")
                }
            }
            .onAppear {
                DebugLogger.shared.log("🟢 WebViewContainer が表示されました", level: "INFO")
                usedata.locationManager.startUpdatingLocation()
                // 更新処理は isUpdateGps が true の場合にのみ実行
                if usedata.isUpdateGps {
                    usedata.getClosestLocation()
                }
            }
            .onDisappear {
                stopProximityCheck() // 画面が閉じたらタイマーを停止
            }
            .onChange(of: usedata.isUpdateGps) { oldValue, newValue in
                if newValue {
                    DebugLogger.shared.log("🟢 位置情報の更新が開始されたため、10秒ごとの処理を開始", level: "INFO")
                    startProximityCheck()
                } else {
                    DebugLogger.shared.log("🛑 位置情報の更新が停止されたため、10秒ごとの処理を停止", level: "INFO")
                    stopProximityCheck()
                }
            }
    }

    /// 10秒ごとに処理を実行
    private func startProximityCheck() {
        stopProximityCheck() // 既存のタイマーがある場合は停止してから新規作成
        proximityTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            DebugLogger.shared.log("⏳ 10秒ごとの処理を実行", level: "INFO")
            usedata.getClosestLocation() // ここに実行したい処理を記述
        }
    }

    /// タイマーを停止
    private func stopProximityCheck() {
        proximityTimer?.invalidate()
        proximityTimer = nil
        DebugLogger.shared.log("🛑 タイマーが停止されました", level: "INFO")
    }
}

