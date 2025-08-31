//
//  MicrophoneRecorder.swift
//  TestApp
//
//  Created by Kusal Kalinga on 2025-08-31.
//

import AVFAudio

protocol MicrophoneRecorderDelegate: AnyObject {
    func recorder(_ recorder: MicrophoneRecorder, didEmitBase64 base64: String)
    func recorder(_ recorder: MicrophoneRecorder, didGetLevel level: Float)
}

final class MicrophoneRecorder {
    weak var delegate: MicrophoneRecorderDelegate?

    private var engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var inputFormat: AVAudioFormat?

    private var tapInstalled = false
    private var started = false
    private var didRetryAfterZeroHz = false

    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16, sampleRate: 16_000, channels: 1, interleaved: false
    )!
    //    private let levelHz: Double = 10.0

    // Emit ~80 ms chunks => 1280 frames at 16 kHz => 2560 bytes
    private let desiredChunkSeconds: Double = 0.08

    // MARK: - Public

    func start() throws {
        guard !started else { return }

        // try configureSession(allowBluetooth: false)
        try preferMicInput()
        usleep(150_000)  // 150 ms settle

        engine = AVAudioEngine()
        try engine.inputNode.setVoiceProcessingEnabled(true)
        let input = engine.inputNode

        // setVoiceProcessingEnabled
        // if routeSupportsVoiceProcessing() { try? input.setVoiceProcessingEnabled(true) }

        let inFormat = input.inputFormat(forBus: 0)
        logDiag(tag: "preTap", inFormat: inFormat)
        guard inFormat.sampleRate > 0, inFormat.channelCount > 0 else {
            throw NSError(
                domain: "MicrophoneRecorder", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid input format"])
        }

        inputFormat = inFormat
        converter = AVAudioConverter(from: inFormat, to: targetFormat)

        installTap(inputNode: input, inputFormat: inFormat)
        try engine.start()
        print("[MicrophoneRecorder] engineRunning=\(engine.isRunning)")
        started = true

    }

    func stop() {
        guard started else { return }
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        engine.stop()
        started = false
        didRetryAfterZeroHz = false
    }

    func adaptToDeviceChange() throws {
        let was = started
        stop()
        if was { try start() }
    }

    // MARK: - Session/Route

    // Configure a record-capable session. If allowBluetooth is false, avoids A2DP-only routing.
    //    private func configureSession(allowBluetooth: Bool) throws {
    //        let s = AVAudioSession.sharedInstance()
    //        let opts: AVAudioSession.CategoryOptions = [.defaultToSpeaker, .allowBluetooth, .duckOthers]
    //        // if allowBluetooth { opts.insert(.allowBluetooth) }
    //        try s.setCategory(.playAndRecord, mode: .voiceChat, options: opts)
    //        try s.setActive(true)
    //        logSession("configured \(allowBluetooth ? "with" : "without") BT")
    //        logRoute()
    //    }

    // Prefer a real microphone input if available.
    private func preferMicInput() throws {
        let s = AVAudioSession.sharedInstance()
        let inputs = s.availableInputs ?? []
        if let builtIn = inputs.first(where: { $0.portType == .builtInMic }) {
            try? s.setPreferredInput(builtIn)
        } else if let headset = inputs.first(where: { $0.portType == .headsetMic }) {
            try? s.setPreferredInput(headset)
        } else if let hfp = inputs.first(where: { $0.portType == .bluetoothHFP }) {
            try? s.setPreferredInput(hfp)
        }
        //        try? s.setActive(true)
        logRoute()
    }

    private func routeSupportsVoiceProcessing() -> Bool {
        let inputPort = AVAudioSession.sharedInstance().currentRoute.inputs.first?.portType
        switch inputPort {
        case .builtInMic?, .headsetMic?, .bluetoothHFP?:
            return true
        default:
            return false
        }
    }

    // Rearm session and rebuild engine while avoiding Bluetooth (to bypass A2DP-only cases).
    //    private func rearmSessionAndEngineWithoutBluetooth() throws {
    //        let s = AVAudioSession.sharedInstance()
    //        try? s.setActive(false, options: [.notifyOthersOnDeactivation])
    //        try configureSession(allowBluetooth: false)
    //        engine = AVAudioEngine()
    //    }

    // MARK: - Tap/Conversion

    private func installTap(inputNode: AVAudioInputNode, inputFormat: AVAudioFormat) {
        guard !tapInstalled else { return }

        // Desired chunk length at 16 kHz
        let desiredOutFrames = AVAudioFrameCount(targetFormat.sampleRate * desiredChunkSeconds)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) {
            [weak self] inBuf, _ in
            guard let self = self, let converter = self.converter else { return }

            // Prepare output buffer
            guard
                let outBuffer = AVAudioPCMBuffer(
                    pcmFormat: self.targetFormat, frameCapacity: desiredOutFrames)
            else { return }

            var error: NSError?

            // Convert Float32 input buffer to Int16 target buffer
            converter.convert(to: outBuffer, error: &error) { inNumPackets, status in
                status.pointee = .haveData
                return inBuf
            }

            if let err = error {
                print("[MicrophoneRecorder] convert error: \(err)")
                return
            }

            // Send Int16 PCM data as base64
            guard let ch = outBuffer.int16ChannelData?.pointee else { return }
            let data = Data(bytes: ch, count: Int(outBuffer.frameLength) * MemoryLayout<Int16>.size)
            self.delegate?.recorder(self, didEmitBase64: data.base64EncodedString())
        }

        tapInstalled = true
    }

    // MARK: - Helpers

    private static func segment(
        of buf: AVAudioPCMBuffer,
        from: AVAudioFramePosition,
        to: AVAudioFramePosition
    ) -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(to - from)
        guard let seg = AVAudioPCMBuffer(pcmFormat: buf.format, frameCapacity: frames) else {
            return nil
        }
        let bpf = Int(buf.format.streamDescription.pointee.mBytesPerFrame)
        let src = UnsafeMutableAudioBufferListPointer(buf.mutableAudioBufferList)
        let dst = UnsafeMutableAudioBufferListPointer(seg.mutableAudioBufferList)
        for (s, d) in zip(src, dst) {
            if let sd = s.mData {
                memcpy(d.mData, sd.advanced(by: Int(from) * bpf), Int(frames) * bpf)
            }
        }
        seg.frameLength = frames
        return seg
    }

    private func logSession(_ tag: String) {
        let s = AVAudioSession.sharedInstance()
        print(
            "[MicrophoneRecorder] session(\(tag)): cat=\(s.category.rawValue) mode=\(s.mode.rawValue)"
        )
    }

    private func logRoute() {
        let s = AVAudioSession.sharedInstance()
        let inPorts = s.currentRoute.inputs.map { $0.portType.rawValue }
        let outPorts = s.currentRoute.outputs.map { $0.portType.rawValue }
        print("[MicrophoneRecorder] route inputs=\(inPorts) outputs=\(outPorts)")
    }

    private func logDiag(tag: String, inFormat: AVAudioFormat) {
        logSession(tag)
        logRoute()
        print(
            "[MicrophoneRecorder] \(tag) inputFormat: \(inFormat.sampleRate) Hz, \(inFormat.channelCount) ch"
        )
    }

    private func log(_ s: String) { print("[MicrophoneRecorder] \(s)") }
}

