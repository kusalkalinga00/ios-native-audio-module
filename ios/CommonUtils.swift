//
//  CommonUtils.swift
//  TestApp
//
//  Created by Kusal Kalinga on 2025-08-31.
//

import AVFAudio

enum CommonUtils {
    static let serverAudioFormat: AVAudioFormat = {
        AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 24_000,
            channels: 1,
            interleaved: false
        )!
    }()

    static let audioLevelReportingRate = 10

    static func calculateRMS(from buffer: AVAudioPCMBuffer) -> Float {
        guard let ch = buffer.floatChannelData?.pointee else { return 0 }
        let n = Int(buffer.frameLength)
        if n == 0 { return 0 }
        var sum: Float = 0
        for i in 0..<n { sum += ch[i] * ch[i] }
        return sqrt(sum / Float(n))
    }

    static func installAudioLevelTap(on node: AVAudioNode, callback: @escaping (Float) -> Void) {
        let format = node.outputFormat(forBus: 0)
        let bufferSize = AVAudioFrameCount(format.sampleRate / Double(audioLevelReportingRate))
        node.installTap(onBus: 0, bufferSize: bufferSize, format: format) { buffer, _ in
            callback(calculateRMS(from: buffer))
        }
    }

    static func uninstallAudioLevelTap(on node: AVAudioNode) {
        node.removeTap(onBus: 0)
    }
}

