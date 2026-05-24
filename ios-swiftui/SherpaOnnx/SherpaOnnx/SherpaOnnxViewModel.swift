//
//  SherpaOnnxViewModel.swift
//  SherpaOnnx
//
//  Created by knight on 2023/4/5.
//

import AVFoundation
import Foundation

enum RecordingState: Equatable {
    case idle
    case preparing
    case recording
    case stopped
    case failed
}

enum SubtitleError: LocalizedError {
    case microphoneDenied
    case missingRecognizer
    case missingAudioEngine

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return "麦克风权限未开启"
        case .missingRecognizer:
            return "识别器未准备好"
        case .missingAudioEngine:
            return "音频引擎未准备好"
        }
    }
}

@MainActor
final class SherpaOnnxViewModel: ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var subtitleText: String = ""
    @Published var statusMessage: String = "点击开始，实时收音识别"
    @Published var errorMessage: String = ""

    private let audioSession = AVAudioSession.sharedInstance()
    private var audioEngine: AVAudioEngine?
    private var recognizer: SherpaOnnxRecognizer?

    private var finalLines: [String] = []
    private let maxFinalLines = 40

    var allText: String {
        var lines = finalLines
        if !subtitleText.isEmpty {
            lines.append(subtitleText)
        }
        return lines.joined(separator: "\n")
    }

    var isRunning: Bool {
        state == .recording
    }

    func toggleRecorder() async {
        if isRunning {
            stopRecorder()
        } else {
            await startRecorder()
        }
    }

    func clearTranscript() {
        finalLines.removeAll()
        subtitleText = ""
    }

    func stopRecorder() {
        audioEngine?.stop()
        audioEngine = nil
        recognizer?.reset()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
        subtitleText = ""
        statusMessage = "已停止"
        state = .stopped
    }

    private func startRecorder() async {
        state = .preparing
        errorMessage = ""
        statusMessage = "正在准备模型"

        do {
            let granted = await requestMicrophonePermission()
            guard granted else {
                throw SubtitleError.microphoneDenied
            }

            try configureAudioSession()

            let modelRoot = try await ChineseParaformerModelStore.shared.ensureDownloaded { [weak self] message in
                self?.statusMessage = message
            }

            if recognizer == nil {
                recognizer = try makeRecognizer(modelRoot: modelRoot)
            }

            guard let recognizer else {
                throw SubtitleError.missingRecognizer
            }

            try configureAudioEngine(recognizer: recognizer)

            clearTranscript()
            statusMessage = "正在收音"
            try audioSession.setActive(true)
            audioEngine?.prepare()
            try audioEngine?.start()
            state = .recording
        } catch {
            stopRecorder()
            state = .failed
            statusMessage = "启动失败"
            errorMessage = error.localizedDescription
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func configureAudioSession() throws {
        try audioSession.setCategory(.record, mode: .measurement, options: [])
        try audioSession.setPreferredSampleRate(16_000)
        try audioSession.setPreferredIOBufferDuration(0.02)
    }

    private func makeRecognizer(modelRoot: URL) throws -> SherpaOnnxRecognizer {
        let modelConfig = makeChineseStreamingParaformerModelConfig(modelRoot: modelRoot)
        let featConfig = sherpaOnnxFeatureConfig(
            sampleRate: 16_000,
            featureDim: 80
        )

        var config = sherpaOnnxOnlineRecognizerConfig(
            featConfig: featConfig,
            modelConfig: modelConfig,
            enableEndpoint: true,
            rule1MinTrailingSilence: 1.2,
            rule2MinTrailingSilence: 0.8,
            rule3MinUtteranceLength: 20,
            decodingMethod: "greedy_search",
            maxActivePaths: 4
        )

        return SherpaOnnxRecognizer(config: &config)
    }

    private func configureAudioEngine(recognizer: SherpaOnnxRecognizer) throws {
        audioEngine?.stop()
        audioEngine = nil

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputBus = 0
        let inputFormat = inputNode.outputFormat(forBus: inputBus)

        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        ) else {
            throw SubtitleError.missingAudioEngine
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw SubtitleError.missingAudioEngine
        }

        inputNode.installTap(
            onBus: inputBus,
            bufferSize: 512,
            format: inputFormat
        ) { buffer, _ in
            var newBufferAvailable = true

            let inputCallback: AVAudioConverterInputBlock = { _, outStatus in
                if newBufferAvailable {
                    outStatus.pointee = .haveData
                    newBufferAvailable = false
                    return buffer
                } else {
                    outStatus.pointee = .noDataNow
                    return nil
                }
            }

            let frameCapacity = AVAudioFrameCount(outputFormat.sampleRate)
                * buffer.frameLength
                / AVAudioFrameCount(buffer.format.sampleRate) + 1

            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: frameCapacity
            ) else {
                return
            }

            var conversionError: NSError?
            let status = converter.convert(
                to: convertedBuffer,
                error: &conversionError,
                withInputFrom: inputCallback
            )

            guard status != .error, conversionError == nil else {
                return
            }

            let samples = convertedBuffer.array()
            guard !samples.isEmpty else {
                return
            }

            recognizer.acceptWaveform(samples: samples)
            while recognizer.isReady() {
                recognizer.decode()
            }

            let result = recognizer.getResult().text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            let endpoint = recognizer.isEndpoint()

            if !result.isEmpty {
                DispatchQueue.main.async {
                    self.subtitleText = result
                }
            }

            if endpoint {
                if !result.isEmpty {
                    DispatchQueue.main.async {
                        self.finalLines.append(result)
                        if self.finalLines.count > self.maxFinalLines {
                            self.finalLines.removeFirst(self.finalLines.count - self.maxFinalLines)
                        }
                        self.subtitleText = ""
                    }
                }
                recognizer.reset()
            }
        }

        audioEngine = engine
    }
}
