//
//  AudioSessionManager.swift
//  MushafImad
//
//  Centralizes AVAudioSession configuration and interruption handling for
//  background audio playback. The view model and example app interact with
//  this singleton to prepare the audio session and respond to system events.
//

import AVFoundation

@MainActor
public final class AudioSessionManager {
    public static let shared = AudioSessionManager()

    private init() {}

    /// Configures the shared AVAudioSession for long‑lived playback. This should
    /// be invoked early in the app’s lifecycle, typically at launch or when the
    /// first player is created.
    public func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    /// Registers handlers for audio session interruptions (incoming calls,
    /// system alerts, etc.). The caller is responsible for pausing/resuming the
    /// active player when these closures fire.
    public func setupInterruptionHandling(
        onInterruptionBegan: @escaping () -> Void,
        onInterruptionEnded: @escaping () -> Void
    ) {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { notification in
            guard let typeRaw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else {
                return
            }

            switch type {
            case .began:
                onInterruptionBegan()
            case .ended:
                let optionsRaw = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
                let shouldResume = optionsRaw == AVAudioSession.InterruptionOptions.shouldResume.rawValue
                if shouldResume {
                    onInterruptionEnded()
                }
            @unknown default:
                break
            }
        }
    }
}
