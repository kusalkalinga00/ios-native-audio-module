//
//  AudioPlayer.swift
//  TestApp
//
//  Created by Kusal Kalinga on 2025-08-31.
//

import AVFAudio

protocol AudioPlayerDelegate: AnyObject {
    func audioPlayerDidStart(_ player: RNAudioPlayer)
    func audioPlayerDidFinish(_ player: RNAudioPlayer)
    func audioPlayer(_ player: RNAudioPlayer, didGetLevel level: Float)
}

final class AudioPlayer {
    weak var delegate: AudioPlayerDelegate?

    private var engine = AVAudioEngine()
    private var node = AVAudioPlayerNode()
    private let inputFormat = CommonUtils.serverAudioFormat
    private let playerFormat: AVAudioFormat
    private let converter: AVAudioConverter
    private var enqueued = 0
    private var started = false
    private var tapInstalled = false

    init() {
        playerFormat = AVAudioFormat(
            standardFormatWithSampleRate: inputFormat.sampleRate,
            channels: inputFormat.channelCount
        )!
        converter = AVAudioConverter(from: inputFormat, to: playerFormat)!
    }

    func start() throws {
        guard !started else { return }
        engine = AVAudioEngine()
        node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: playerFormat)

        if !tapInstalled {
          CommonUtils.installAudioLevelTap(on: node) { [weak self] level in
                guard let self else { return }
                self.delegate?.audioPlayer(self, didGetLevel: level)
            }
            tapInstalled = true
        }

        try engine.start()
        node.play()
        started = true
    }

    func stop() {
        if tapInstalled {
          CommonUtils.uninstallAudioLevelTap(on: node)
            tapInstalled = false
        }
        node.stop()
        engine.stop()
        enqueued = 0
        started = false
    }

    func clearQueue() {
        guard started else { return }
        node.stop()
        enqueued = 0
        node.play()
    }

    func playBase64Chunk(_ base64: String) {
        guard started, let data = Data(base64Encoded: base64) else { return }

        let bytesPerFrame = Int(inputFormat.streamDescription.pointee.mBytesPerFrame)  // 2
        let frames = AVAudioFrameCount(data.count / bytesPerFrame)
        guard frames > 0 else { return }

        guard
            let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: frames),
            let outBuffer = AVAudioPCMBuffer(pcmFormat: playerFormat, frameCapacity: frames)
        else { return }

        inputBuffer.frameLength = frames
        data.withUnsafeBytes { raw in
            if let dst = inputBuffer.int16ChannelData?.pointee, let src = raw.baseAddress {
                memcpy(dst, src, data.count)
            }
        }

        do {
            try converter.convert(to: outBuffer, from: inputBuffer)
        } catch {
            return  // drop bad chunk
        }

        incrementEnqueued()
        node.scheduleBuffer(outBuffer, completionCallbackType: .dataPlayedBack) {
            [weak self] type in
            guard let self, type == .dataPlayedBack else { return }
            self.decrementEnqueued()
        }
    }

    private func incrementEnqueued() {
        enqueued += 1
        if enqueued == 1 {
            delegate?.audioPlayerDidStart(self)
        }
    }

    private func decrementEnqueued() {
        if enqueued > 0 {
            enqueued -= 1
            if enqueued == 0 {
                delegate?.audioPlayerDidFinish(self)
            }
        }
    }
}

