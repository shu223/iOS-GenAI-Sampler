//
//  RealtimeCameraView.swift
//  iOS-GenAI-Sampler
//
//  Created by Shuichi Tsutsumi on 2024/05/20.
//

import SwiftUI

struct RealtimeCameraView: View {
    @StateObject var captureManager = RealtimeCameraManager()

    var body: some View {
        VStack {
            CameraPreview(captureManager: captureManager)
                .onAppear {
                    Task {
                        if await captureManager.requestAccess() {
                            print("Camera access granted")
                            captureManager.startCapture()
                        } else {
                            print("Camera access denied")
                        }
                    }
                }
                .onDisappear(perform: {
                    captureManager.stopCapture()
                })
            VStack {
                Text(captureManager.resultText)
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                    .padding(16)

                Spacer()

                Toggle(isOn: $captureManager.useJP) {
                    Text(captureManager.useJP ? "日本語" : "English")
                        .foregroundColor(.white)
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: 200, alignment: .leading)
            .background(Color.black)
        }
    }
}

#Preview {
    RealtimeCameraView()
}

struct CameraPreview: UIViewRepresentable {
    var captureManager = RealtimeCameraManager()

    init(captureManager: RealtimeCameraManager) {
        self.captureManager = captureManager
    }

    func makeUIView(context _: Context) -> UIView {
        print("\(type(of: self))/\(#function)")
        let view = UIView(frame: UIScreen.main.bounds)

        let previewView = UIView(frame: view.bounds)
        previewView.backgroundColor = UIColor.black
        view.addSubview(previewView)

        captureManager.initialize(with: previewView)

        return view
    }

    func updateUIView(_: UIView, context _: Context) {
        print("\(type(of: self))/\(#function)")
        captureManager.videoCapture?.resizePreview()
    }
}
