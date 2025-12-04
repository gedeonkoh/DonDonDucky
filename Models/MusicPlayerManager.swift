//
//  MusicPlayerManager.swift
//  r1
//
//  Created by Gedeon Koh on 3/12/25.
//

import Foundation
import MediaPlayer
import SwiftUI
import Combine

class MusicPlayerManager: ObservableObject {
    let musicPlayer = MPMusicPlayerController.applicationMusicPlayer
    private let systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer
    
    @Published var nowPlaying: MPMediaItem?
    @Published var isPlaying = false
    @Published var playbackTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isShuffling = false
    @Published var repeatMode: MPMusicRepeatMode = .none
    @Published var playlists: [MPMediaPlaylist] = []
    
    private var timer: Timer?
    
    init() {
        setupNotifications()
        loadPlaylists()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingItemChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackStateChanged),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer
        )
        
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    @objc private func nowPlayingItemChanged() {
        DispatchQueue.main.async {
            self.nowPlaying = self.musicPlayer.nowPlayingItem
            self.duration = self.nowPlaying?.playbackDuration ?? 0
        }
    }
    
    @objc private func playbackStateChanged() {
        DispatchQueue.main.async {
            self.isPlaying = self.musicPlayer.playbackState == .playing
            if self.isPlaying {
                self.startTimer()
            } else {
                self.stopTimer()
            }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updatePlaybackTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updatePlaybackTime() {
        playbackTime = musicPlayer.currentPlaybackTime
    }
    
    func requestAuthorization() async -> Bool {
        let status = await MPMediaLibrary.requestAuthorization()
        return status == .authorized
    }
    
    func play() {
        musicPlayer.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        musicPlayer.pause()
        isPlaying = false
        stopTimer()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func skipToNext() {
        musicPlayer.skipToNextItem()
    }
    
    func skipToPrevious() {
        musicPlayer.skipToPreviousItem()
    }
    
    func seek(to time: TimeInterval) {
        musicPlayer.currentPlaybackTime = time
        playbackTime = time
    }
    
    func skipForward(seconds: TimeInterval = 15) {
        let newTime = min(playbackTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(seconds: TimeInterval = 15) {
        let newTime = max(playbackTime - seconds, 0)
        seek(to: newTime)
    }
    
    func toggleShuffle() {
        isShuffling.toggle()
        musicPlayer.shuffleMode = isShuffling ? .songs : .off
    }
    
    func setRepeatMode(_ mode: MPMusicRepeatMode) {
        repeatMode = mode
        musicPlayer.repeatMode = mode
    }
    
    func toggleRepeat() {
        switch repeatMode {
        case .none:
            setRepeatMode(.one)
        case .one:
            setRepeatMode(.all)
        case .all:
            setRepeatMode(.none)
        default:
            setRepeatMode(.none)
        }
    }
    
    func playPlaylist(_ playlist: MPMediaPlaylist, shuffle: Bool = true) {
        let collection = MPMediaItemCollection(items: playlist.items)
        musicPlayer.setQueue(with: collection)
        
        if shuffle {
            musicPlayer.shuffleMode = .songs
            isShuffling = true
        }
        
        musicPlayer.play()
        isPlaying = true
        startTimer()
    }
    
    func loadPlaylists() {
        let query = MPMediaQuery.playlists()
        if let collections = query.collections {
            playlists = collections.compactMap { $0 as? MPMediaPlaylist }
        }
    }
    
    @Published var isFavorited: Bool = false
    
    func toggleFavorite() {
        isFavorited.toggle()
        // This would require additional implementation with MusicKit
        // For now, we'll just toggle a local state
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        musicPlayer.endGeneratingPlaybackNotifications()
        stopTimer()
    }
}

