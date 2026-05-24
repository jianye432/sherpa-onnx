# Windows 安装说明

你没有 Mac 的情况下，可以用 `GitHub Actions + AltStore/AltServer` 装到 iPhone 上。

## 1. 生成 IPA
1. 把这个仓库推到你自己的 GitHub 仓库。
2. 在 GitHub Actions 里手动运行 `build-ios-ipa`。
3. 下载构建产物 `HearingSubtitle.ipa`。

## 2. Windows 端准备
1. 安装 Apple 官方版 `iTunes` 和 `iCloud`。
2. 安装 `AltServer for Windows`。
3. 用 USB 连接 iPhone，解锁并信任电脑。
4. iPhone 打开 `设置 > 隐私与安全性 > 开发者模式`。

## 3. 安装到 iPhone
1. 打开 `AltServer`。
2. 先安装 `AltStore` 到手机，或直接用 AltServer 侧载 `HearingSubtitle.ipa`。
3. 输入你的 Apple ID 进行签名。
4. 安装完成后，在手机里信任开发者证书。

## 4. 使用限制
- 免费 Apple ID 一般需要每 7 天刷新一次。
- App 只能用麦克风，不会读取电话和蓝牙耳机里的内部音频。
