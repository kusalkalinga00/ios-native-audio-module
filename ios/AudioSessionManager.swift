//
//  AudioSessionManager.swift
//  TestApp
//
//  Created by Kusal Kalinga on 2025-08-31.
//


import AVFAudio

final class AudioSessionManager {
  static let shared = AudioSessionManager()
  private let session = AVAudioSession.sharedInstance()
  private var configured = false

  private init() {}

  /// Configure a duplex session once and keep it active.
  func activateDuplexSession() throws {
    // Idempotent guard — avoids reconfiguring during restarts
    if !configured {
      // Full-duplex: record + playback + AEC/AGC/NS via .voiceChat
      try session.setCategory(
        .playAndRecord,
        mode: .voiceChat,
        options: [.defaultToSpeaker, .allowBluetooth, .duckOthers]
      )
      // Optional tuning (helps reduce end-to-end latency)
//      try? session.setPreferredSampleRate(24_000)          // match your server format
//      try? session.setPreferredIOBufferDuration(0.02)      // ~20ms buffer
      configured = true
    }

    // (Re)activate the session
    try session.setActive(true, options: .notifyOthersOnDeactivation)
  }

  func deactivate() {
    try? session.setActive(false, options: [.notifyOthersOnDeactivation])
  }
}

