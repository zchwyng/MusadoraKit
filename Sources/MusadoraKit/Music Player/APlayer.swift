//
//  APlayer.swift
//  MusadoraKit
//
//  Created by Rudrank Riyam on 07/03/23.
//

import Foundation
import MusicKit

@available(macOS, unavailable)
@available(watchOS, unavailable)
public typealias APlayer = ApplicationMusicPlayer

@available(macOS, unavailable)
@available(watchOS, unavailable)
public extension APlayer {
  func play(song: Song) async throws {
    queue = [song]
    try await play()
  }

  func play(songs: Songs) async throws {
    queue = ApplicationMusicPlayer.Queue(for: songs)
    try await play()
  }

  func play(song: Song, at position: APlayer.Queue.EntryInsertionPosition) async throws {
    try await queue.insert(song, position: position)
    try await play()
  }
}

@available(macOS, unavailable)
@available(watchOS, unavailable)
public extension APlayer {
  func play(station: Station) async throws {
    queue = [station]
    try await play()
  }
}

@available(macOS, unavailable)
@available(watchOS, unavailable)
public extension APlayer {
  func play(playlist: Playlist) async throws {
    queue = [playlist]
    try await play()
  }
}

@available(macOS, unavailable)
@available(watchOS, unavailable)
public extension APlayer {
  func play(album: Album) async throws {
    queue = [album]
    try await play()
  }
}
