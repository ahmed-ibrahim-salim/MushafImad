//
//  BackgroundPlaybackHelper.swift
//  MushafImad
//
//  Observes a QuranPlayerViewModel to configure the audio session, update
//  lock-screen metadata, handle remote commands, and respond to interruptions.
//  Extracting this logic keeps the view model focused on playback state.
//

import Foundation
import Combine
import MediaPlayer

@MainActor
public final class BackgroundPlaybackHelper {
    private var cancellables = Set<AnyCancellable>()
    private weak var playerViewModel: QuranPlayerViewModel?

    public init() {}

    public func attach(to player: QuranPlayerViewModel) {
        // if attaching to a different view model, drop any existing
        // subscriptions so we start fresh.  if it's the same instance, no
        // work is needed at all.
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

        // commands
        LockScreenMetadataManager.shared.setupRemoteCommands(
            onPlayPause: { [weak player] in player?.togglePlayback() },
            onNext: { [weak player] in _ = player?.seekToNextVerse() },
            onPrevious: { [weak player] in _ = player?.seekToPreviousVerse() }
        )

        // subscribe to model updates
        player.$playbackState
            .sink { [weak self] state in
                guard let self, let player = self.playerViewModel, state == .playing else { return }
                LockScreenMetadataManager.shared.setNowPlayingInfo(
                    surahName: player.chapterName,
                    reciterName: player.reciterName,
                    currentTime: player.currentTime,
                    duration: player.duration
                )
            }
            .store(in: &cancellables)

        player.$currentTime
            .sink { [weak self] time in
                guard let _ = self else { return }
                LockScreenMetadataManager.shared.updateElapsedTime(time)
            }
            .store(in: &cancellables)
    }

    public func detach() {
        cancellables.removeAll()
        playerViewModel = nil
    }
}
