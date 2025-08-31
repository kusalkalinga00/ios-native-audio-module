//
//  AudioManagerModule.swift
//  TestApp
//
//  Created by Kusal Kalinga on 2025-08-31.
//

import AVFAudio
import Foundation
import React

@objc(AudioManagerModule)
final class AudioRecorderModule: RCTEventEmitter, AudioPlayerDelegate,
  MicrophoneRecorderDelegate
{
  
  private let player = AudioPlayer()
  private let recorder = MicrophoneRecorder()
  
  // Interruption state
  private var willResumeAfterInterruption = false
  private var observersInstalled = false
  
  override static func requiresMainQueueSetup() -> Bool { true }
  
  override func supportedEvents() -> [String]! {
    // Add playback events if JS listens to them
    return [
      "onAudioData", "onUserLevel", "onPlaybackStarted", "onPlaybackFinished",
    ]
  }
  
  // MARK: - Lifecycle / Session
  
  @objc func start(
    _ resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    DispatchQueue.main.async {
      do {
        
        // Centralized session config/activation
        try AudioSessionManager.shared.activateDuplexSession()
        
        // Wire delegates once
        self.recorder.delegate = self
        self.player.delegate = self
        
        // Start playback engine so playAudioChunk works later
        try self.player.start()
        
        // Listen for interruptions/route-changes to keep duplex healthy
        self.installSessionObserversIfNeeded()
        
        resolve(nil)
      } catch {
        reject("E_AUDIO_START", "Failed to start audio: \(error.localizedDescription)", error)
      }
    }
  }
  
  // Optional stop to clean up (not required by your flow)
  @objc func stop(
    _ resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    DispatchQueue.main.async {
      self.recorder.stop()
      self.player.stop()
      //      self.removeSessionObserversIfInstalled()
      AudioSessionManager.shared.deactivate()
      resolve(nil)
    }
  }
  
  // MARK: - Recording API
  
  @objc func startRecording(
    _ resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ) {
    DispatchQueue.main.async {
      do {
        try self.recorder.start()
        resolve(nil)
      } catch {
        reject("rec_start_error", "\(error)", error)
      }
    }
  }
  
  @objc func stopRecording() {
    DispatchQueue.main.async {
      self.recorder.stop()
    }
  }
  
  // MARK: - Playback API
  
  @objc func playAudioChunk(_ base64: String) {
    player.playBase64Chunk(base64)
  }
  
  @objc func clearQueue() {
    player.clearQueue()
  }
  
  @objc func stopAudio() {
    player.clearQueue()
  }
  
  // MARK: - MicrophoneRecorderDelegate
  
  func recorder(_ recorder: MicrophoneRecorder, didEmitBase64 base64: String) {
    sendEvent(withName: "onAudioData", body: base64)
  }
  
  func recorder(_ recorder: MicrophoneRecorder, didGetLevel level: Float) {
    sendEvent(withName: "onUserLevel", body: ["level": level])
  }
  
  // MARK: - RNAudioPlayerDelegate
  
  func audioPlayerDidStart(_ player: AudioPlayer) {
    sendEvent(withName: "onPlaybackStarted", body: nil)
  }
  
  func audioPlayerDidFinish(_ player: AudioPlayer) {
    sendEvent(withName: "onPlaybackFinished", body: nil)
  }
  
  func audioPlayer(_ player: AudioPlayer, didGetLevel level: Float) {
//    sendEvent(withName: "onPlaybackLevel", body: ["level": level])
  }
  
  
  // MARK: - Interruption & Route Handling
  
  private func installSessionObserversIfNeeded() {
    guard !observersInstalled else { return }
    observersInstalled = true
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification,
      object: AVAudioSession.sharedInstance()
    )
  }
  
  private func removeSessionObserversIfInstalled() {
    guard observersInstalled else { return }
    observersInstalled = false
    NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
//  NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
  }
    
    
    @objc private func handleInterruption(_ note: Notification) {
      print("[AudioRecorderModule] Interruption received")
      
      
      guard
        let info = note.userInfo,
        let typeVal = info[AVAudioSessionInterruptionTypeKey] as? UInt,
        let type = AVAudioSession.InterruptionType(rawValue: typeVal)
      else {
        print("[AudioRecorderModule] Interruption: could not get type from notification")
        return
      }
      
      switch type {
      case .began:
        print("[AudioRecorderModule] Interruption began")
        // Pause/stop engines quickly. Mark for resume.
        willResumeAfterInterruption = true
        print("[AudioRecorderModule] Stopping recorder and player due to interruption")
        recorder.stop()         // stop tap/engine cleanly
        player.stop()           // stop engine to avoid render errors
        
      case .ended:
        print("[AudioRecorderModule] Interruption ended")
        // Check if iOS says it’s OK to resume (often true)
        let optionsVal = info[AVAudioSessionInterruptionOptionKey] as? UInt
        let shouldResume = optionsVal.map { AVAudioSession.InterruptionOptions(rawValue: $0).contains(.shouldResume) } ?? true
        print("[AudioRecorderModule] shouldResume = \(shouldResume), willResumeAfterInterruption = \(willResumeAfterInterruption)")
        
        guard willResumeAfterInterruption, shouldResume else {
          
          print("[AudioRecorderModule] Not resuming engines after interruption")
          return
        }
        
        
        willResumeAfterInterruption = false
        
        // Reactivate session and restart engines
        do {
          print("[AudioRecorderModule] Reactivating audio session")
          try AudioSessionManager.shared.activateDuplexSession()
          
          print("[AudioRecorderModule] Restarting player")
          try player.start()
          // Only restart recording if the JS side still wants it (you can track a flag).
          // Here we optimistically restart:
          print("[AudioRecorderModule] Restarting recorder (if JS still wants it)")
          try? recorder.start()
          print("[AudioRecorderModule] Interruption recovery completed")
        } catch {
          print("[AudioRecorderModule] Error during interruption recovery: \(error)")
          // Swallow errors to avoid crashing; JS can call start() again if needed.
          // You may want to emit an event to JS indicating recovery failed.
        }
      @unknown default:
        print("[AudioRecorderModule] Unknown interruption type: \(typeVal)")
//        break
      }
    }
    
    //    @objc private func handleRouteChange(_ note: Notification) {
    //      guard
    //        let info = note.userInfo,
    //        let reasonVal = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
    //        let reason = AVAudioSession.RouteChangeReason(rawValue: reasonVal)
    //      else { return }
    //
    //      switch reason {
    //      case .newDeviceAvailable, .oldDeviceUnavailable, .categoryChange, .override:
    //        // Rebuild engines against the new route
    //        do {
    //          try AudioSessionManager.shared.activateDuplexSession()
    //          // Player is stateless — just ensure engine is running
    //          try? player.start()
    //          // Recorder needs to rebuild its engine/tap with the new input format
    //          try? recorder.adaptToDeviceChange()
    //        } catch {
    //          // Optionally emit a JS event about route-change recovery failure
    //        }
    //      default:
    //        break
    //      }
    //    }
  }




