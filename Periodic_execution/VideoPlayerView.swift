import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL
    @State private var player: AVPlayer
    @Environment(\.dismiss) var dismiss // ✅ `LocationView` に戻るための dismiss()

    init(videoURL: URL) {
        self.videoURL = videoURL
        self._player = State(initialValue: AVPlayer(url: videoURL))
    }

    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .onAppear {
                    // 🎬 自動再生
                    player.play()
                    
                    // ✅ 動画が終了したら `LocationView` に戻る
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: player.currentItem,
                        queue: .main
                    ) { _ in
                        dismiss() // `LocationView` に戻る
                    }
                }
                .onDisappear {
                    // ⏹️ 画面を閉じたら動画を停止
                    player.pause()
                    
                    // ✅ `NotificationCenter` の登録を解除
                    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
                }
                .edgesIgnoringSafeArea(.all) // フルスクリーン表示
            
            // 🔽 戻るボタン（動画上にオーバーレイ）
            VStack {
                HStack {
                    Button(action: {
                        dismiss() // `LocationView` に戻る
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
            }
        }
    }
}
