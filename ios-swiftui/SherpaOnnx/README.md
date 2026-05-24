# 听障字幕 iOS

这是基于 `sherpa-onnx` 的 iOS 麦克风实时字幕工程。

## 功能
- 仅收集麦克风声音
- 普通话实时转文字
- 点击开始收音，切后台或停止即关闭
- 首次启动自动下载中文流式 Paraformer 模型到本地

## 模型
- 采用中文流式 Paraformer 方案
- 模型文件会下载到 `Application Support/HearingSubtitle/streaming-paraformer-zh`

## 构建提示
- 需要在 macOS + Xcode 上打开 `SherpaOnnx.xcodeproj`
- 需要先准备好 `sherpa-onnx.xcframework` 和 `onnxruntime.xcframework`
- 项目中的 Swift 源码已经改成听障字幕用途
