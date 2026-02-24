//
//  LockScreenMetadataManager.swift
//  MushafImad
//
//  Service that owns the `MPNowPlayingInfoCenter` and  `MPRemoteCommandCenter` 
//  configuration used to display
//  metadata on the lock screen and respond to remote controls.
//

import Foundation
import MediaPlayer

@MainActor
public final class LockScreenMetadataManager {
    public static let shared = LockScreenMetadataManager()

    private init() {}

    /// Updates the system "Now Playing" info dictionary. The host
    /// application calls this whenever playback state or content changes.
    /// Sets every field in the now‑playing dictionary.  This is intended for
    /// situations where the content changes completely (new track/reciter/etc.)
    /// and therefore should only be called infrequently.
    public func setNowPlayingInfo(
        surahName: String,
        reciterName: String,
        duration: TimeInterval,
        artwork: MPMediaItemArtwork? = nil
    ) {
        var info: [String: Any] = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyTitle] = surahName
        info[MPMediaItemPropertyArtist] = reciterName
        info[MPMediaItemPropertyPlaybackDuration] = duration
        if let artwork = artwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Updates only the elapsed playback time.  Call this repeatedly (e.g. once
    /// per second) without touching the other metadata fields.
    public func updateElapsedTime(_ currentTime: TimeInterval) {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Registers remote command handlers using simple closures provided by the
    /// caller.  Doing nothing is a valid customization; commands will be ignored
    /// if the appropriate closure is empty.
    public func setupRemoteCommands(
        onPlayPause: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onPrevious: @escaping () -> Void
    ) {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { _ in
            onPlayPause()
            return .success
        }
        commandCenter.pauseCommand.addTarget { _ in
            onPlayPause()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { _ in
            onNext()
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { _ in
            onPrevious()
            return .success
        }
        AppLogger.shared.info("LockScreenMetadataManager: Remote commands set up", category: .audio)
    }
}
