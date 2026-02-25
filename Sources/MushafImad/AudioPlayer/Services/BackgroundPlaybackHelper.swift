//
//  BackgroundPlaybackHelper.swift
//  MushafImad
//
//  Observes a QuranPlayerViewModel to configure the audio session, update
//  lock-screen metadata, handle remote commands, and respond to interruptions.
//  Extracting this logic keeps the view model focused on playback state.
//

import Combine
import Foundation
import MediaPlayer

@MainActor
public final class BackgroundPlaybackHelper {
  private var cancellables = Set<AnyCancellable>()
  private weak var playerViewModel: QuranPlayerViewModel?

  public init() {}

  public func attach(to player: QuranPlayerViewModel) {
    guard playerViewModel !== player else { return }

    cancellables.removeAll()
    playerViewModel = player

    // ensure session + interruption handling
    Task { @MainActor in
      AudioSessionManager.shared.setupInterruptionHandling(
        onInterruptionBegan: { [weak player] in player?.pause() },
        onInterruptionEnded: { [weak player] in player?.startIfNeeded(autoPlay: true) }
      )
    }

    // Register default remote command handlers only if the app hasn't already
    // configured custom handlers. Apps can call
    // `LockScreenMetadataManager.shared.setupRemoteCommands(...)` at launch to
    // replace these defaults (for example, to register skip ±10s instead of
    // next/previous).
    if !LockScreenMetadataManager.shared.hasRegisteredCommands() {
      LockScreenMetadataManager.shared.setupRemoteCommands(
        .init(
          onPlayPause: { [weak player] in player?.togglePlayback() },
          onSkipForward: { [weak player] in _ = player?.seekToNextVerse() },
          onSkipBackward: { [weak player] in _ = player?.seekToPreviousVerse() }
        )
      )
    }

    // subscribe to updates
    player.$playbackState
      .sink { [weak self] state in
        guard let self, let player = self.playerViewModel else { return }
        let interval: TimeInterval = TimeInterval(Int(player.duration))
        if state == .finished { LockScreenMetadataManager.shared.updateElapsedTime(interval) }
        
        if state == .playing {
          LockScreenMetadataManager.shared.setNowPlayingInfo(
            surahName: player.chapterName,
            reciterName: player.reciterName,
            duration: interval
          )
        }
      }
      .store(in: &cancellables)

    player.$currentTime
      .map { Double(Int($0)) }
      .removeDuplicates()
      .sink { [weak self] time in
        guard self != nil else { return }
          LockScreenMetadataManager.shared.updateElapsedTime(time)
      }
      .store(in: &cancellables)
  }

  public func detach() {
    cancellables.removeAll()
    playerViewModel = nil
  }
}
