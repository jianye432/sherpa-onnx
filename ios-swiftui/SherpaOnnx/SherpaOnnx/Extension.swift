//
//  Extension.swift
//  SherpaOnnx
//
//  Created by knight on 2023/4/5.
//

import AVFoundation

extension AudioBuffer {
    func array() -> [Float] {
        return Array(UnsafeBufferPointer(self))
    }
}

extension AVAudioPCMBuffer {
    func array() -> [Float] {
        return self.audioBufferList.pointee.mBuffers.array()
    }
}

extension TimeInterval {
    var hourMinuteSecondMS: String {
        let totalMilliseconds = Int((self * 1000.0).rounded())
        let hours = totalMilliseconds / 3_600_000
        let minutes = (totalMilliseconds % 3_600_000) / 60_000
        let seconds = (totalMilliseconds % 60_000) / 1_000
        let milliseconds = totalMilliseconds % 1_000

        return String(
            format: "%02d:%02d:%02d,%03d",
            hours, minutes, seconds, milliseconds
        )
    }
}
