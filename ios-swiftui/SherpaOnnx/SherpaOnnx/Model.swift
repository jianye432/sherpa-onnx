import Foundation

enum ModelStoreError: LocalizedError {
    case missingFile(String)
    case invalidDownloadURL

    var errorDescription: String? {
        switch self {
        case let .missingFile(name):
            return "模型文件缺失：\(name)"
        case .invalidDownloadURL:
            return "模型下载地址无效"
        }
    }
}

struct RemoteModelFile {
    let localName: String
    let remoteURL: URL
}

final class ChineseParaformerModelStore {
    static let shared = ChineseParaformerModelStore()

    let modelDirectory: URL
    let files: [RemoteModelFile]

    private init() {
        let baseDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        modelDirectory = baseDirectory
            .appendingPathComponent("HearingSubtitle", isDirectory: true)
            .appendingPathComponent("streaming-paraformer-bilingual-zh-en", isDirectory: true)

        // Official streaming Paraformer family converted from the domestic
        // FunASR/ModelScope ecosystem.
        files = [
            RemoteModelFile(
                localName: "encoder.int8.onnx",
                remoteURL: URL(
                    string:
                        "https://huggingface.co/csukuangfj/sherpa-onnx-streaming-paraformer-bilingual-zh-en/resolve/main/encoder.int8.onnx?download=1"
                )!
            ),
            RemoteModelFile(
                localName: "decoder.int8.onnx",
                remoteURL: URL(
                    string:
                        "https://huggingface.co/csukuangfj/sherpa-onnx-streaming-paraformer-bilingual-zh-en/resolve/main/decoder.int8.onnx?download=1"
                )!
            ),
            RemoteModelFile(
                localName: "tokens.txt",
                remoteURL: URL(
                    string:
                        "https://huggingface.co/csukuangfj/sherpa-onnx-streaming-paraformer-bilingual-zh-en/resolve/main/tokens.txt?download=1"
                )!
            ),
        ]
    }

    func ensureDownloaded(statusUpdate: @escaping (String) -> Void) async throws -> URL {
        try FileManager.default.createDirectory(
            at: modelDirectory,
            withIntermediateDirectories: true
        )

        for file in files {
            let destination = modelDirectory.appendingPathComponent(file.localName)
            if FileManager.default.fileExists(atPath: destination.path) {
                continue
            }

            await MainActor.run {
                statusUpdate("正在下载模型：\(file.localName)")
            }

            let (temporaryURL, _) = try await URLSession.shared.download(from: file.remoteURL)

            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: temporaryURL, to: destination)
        }

        for file in files {
            let destination = modelDirectory.appendingPathComponent(file.localName)
            guard FileManager.default.fileExists(atPath: destination.path) else {
                throw ModelStoreError.missingFile(file.localName)
            }
        }

        await MainActor.run {
            statusUpdate("模型已准备好")
        }

        return modelDirectory
    }
}

func makeChineseStreamingParaformerModelConfig(
    modelRoot: URL
) -> SherpaOnnxOnlineModelConfig {
    let encoder = modelRoot.appendingPathComponent("encoder.int8.onnx").path
    let decoder = modelRoot.appendingPathComponent("decoder.int8.onnx").path
    let tokens = modelRoot.appendingPathComponent("tokens.txt").path

    return sherpaOnnxOnlineModelConfig(
        tokens: tokens,
        paraformer: sherpaOnnxOnlineParaformerModelConfig(
            encoder: encoder,
            decoder: decoder
        ),
        numThreads: 2,
        modelType: "paraformer"
    )
}
