//
//  SideMenuView.swift
//  Periodic_execution
//
//  Created by fukushikyaria2024 on 2025/03/19.
//

// ✅ 右側からスライドするサイドメニュー
import SwiftUI
import MapKit
import CoreLocation

struct SideMenuView: View {
    @EnvironmentObject var usedata: UserSettings
    @Binding var isMenuOpen: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isMenuOpen {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                isMenuOpen = false
                            }
                        }
                }

                HStack {
                    Spacer()

                    VStack(alignment: .center, spacing: 15) {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    isMenuOpen = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                    .frame(width: 70, height: 70)
                            }
                            .padding()
                        }

                        Text("メニュー")
                            .font(.headline)
                            .padding(.top, -10)
                        
                        


                        CustomButton(title: usedata.FakeMode ? "手動モードOFF" : "手動モードON", color: usedata.FakeMode ? .red : .gray) {
                            usedata.FakeMode.toggle()
                            // UserSettings.Keysを使用して保存
                            UserDefaults.standard.set(usedata.FakeMode, forKey: "fake_mode")
                        }
                        

                        Toggle(isOn: $usedata.isUpdateGps) {
                            Text(usedata.isUpdateGps ? "位置情報の更新を停止" : "位置情報の更新")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(usedata.isUpdateGps ? Color.red : Color.blue)
                                .cornerRadius(8)
                        }
                        .toggleStyle(MyToggleStyle())
                        .onChange(of: usedata.isUpdateGps) { oldValue, newValue in
                            if newValue {
                                print("📍 位置情報の更新が開始されました")
                            } else {
                                print("🛑 位置情報の更新が停止されました")
                            }
                            // UserSettings.Keysを使用して保存
                            UserDefaults.standard.synchronize()
                        }
                        


                        
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height) // ✅ 高さを full に変更
                    .background(Color.white)
                    .offset(x: isMenuOpen ? 0 : geometry.size.width)
                    .animation(.easeInOut, value: isMenuOpen)

                }
            }
        }
    }
    

}

// MARK: - カスタムボタンビュー
struct CustomButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 300)
                .background(color)
                .cornerRadius(8)
        }
        .padding(.horizontal, 10)
    }
}
// MARK: - カスタムボタンビュー
struct CustomNavButton<Destination: View>: View {
    let title: String
    let color: Color
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 300)
                .background(color)
                .cornerRadius(8)
        }
        .padding(.horizontal, 10)
    }
}
// MARK: - トグルボタンのカスタム
struct MyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            // ラベルとトグルの間に必要ならSpacer()を追加できます
            RoundedRectangle(cornerRadius: 12.0)
                .frame(width: 42, height: 24)
                .foregroundColor(configuration.isOn ? Color.green : Color.gray)
                .overlay(
                    Circle()
                        .padding(3)
                        .foregroundColor(.white)
                        .offset(x: configuration.isOn ? 8 : -8)
                        .animation(.linear, value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
        .padding(.horizontal)
    }
}



