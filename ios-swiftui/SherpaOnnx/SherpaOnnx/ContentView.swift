//
//  ContentView.swift
//  SherpaOnnx
//

import SwiftUI

struct ContentView: View {
    @StateObject private var subtitleViewModel = SherpaOnnxViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.08, green: 0.09, blue: 0.12),
                    Color(red: 0.02, green: 0.02, blue: 0.03),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                header
                transcriptPanel
                liveCaptionBar
                controls
            }
            .padding()
        }
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                subtitleViewModel.stopRecorder()
            }
        }
        .onDisappear {
            subtitleViewModel.stopRecorder()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("听障字幕")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("仅使用麦克风收音，离开或停止后不再识别。")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            Text(subtitleViewModel.statusMessage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var transcriptPanel: some View {
        ScrollView {
            Text(subtitleViewModel.allText.isEmpty ? "等待开始..." : subtitleViewModel.allText)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var liveCaptionBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("实时字幕")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))

            Text(subtitleViewModel.subtitleText.isEmpty ? "开始后这里会显示最新识别结果" : subtitleViewModel.subtitleText)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await subtitleViewModel.toggleRecorder()
                }
            } label: {
                HStack(spacing: 10) {
                    if subtitleViewModel.state == .preparing {
                        ProgressView()
                            .tint(.black)
                    }
                    Text(subtitleViewModel.isRunning ? "停止" : "开始")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(subtitleViewModel.isRunning ? Color.red : Color.green)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(subtitleViewModel.state == .preparing)

            Button {
                subtitleViewModel.clearTranscript()
            } label: {
                Text("清空")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(width: 84)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.12))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .overlay(alignment: .bottomLeading) {
            if !subtitleViewModel.errorMessage.isEmpty {
                Text(subtitleViewModel.errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red.opacity(0.9))
                    .padding(.top, 56)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
