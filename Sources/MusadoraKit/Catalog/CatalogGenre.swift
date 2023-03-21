//
//  CatalogGenre.swift
//  MusadoraKit
//
//  Created by Rudrank Riyam on 17/08/21.
//

import Foundation

public extension MCatalog {
  /// Fetch a genre from the Apple Music catalog by using its identifier.
  /// - Parameters:
  ///   - id: The unique identifier for the genre.
  /// - Returns: `Genre` matching the given identifier.
  static func genre(id: MusicItemID) async throws -> Genre {
    let request = MusicCatalogResourceRequest<Genre>(matching: \.id, equalTo: id)
    let response = try await request.response()
    
    guard let genre = response.items.first else {
      throw MusadoraKitError.notFound(for: id.rawValue)
    }
    return genre
  }
  
  /// Fetch multiple genres from the Apple Music catalog by using their identifiers.
  /// - Parameters:
  ///   - ids: The unique identifiers for the genres.
  /// - Returns: `Genres` matching the given identifiers.
  static func genres(ids: [MusicItemID]) async throws -> Genres {
    let request = MusicCatalogResourceRequest<Genre>(matching: \.id, memberOf: ids)
    let response = try await request.response()
    return response.items
  }
  
  /// Fetch top genres from the Apple Music catalog.
  /// - Returns: Top `Genres`.
  static func topGenres() async throws -> Genres {
#if compiler(>=5.7)
    if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
      let request = MusicCatalogResourceRequest<Genre>()
      let response = try await request.response()
      return response.items
    } else {
      return try await topGenresAPI()
    }
#else
    return try await topGenresAPI()
#endif
  }
}

extension MCatalog {
  static private func topGenresAPI() async throws -> Genres {
    let storefront = try await MusicDataRequest.currentCountryCode
    let url = try topGenresURL(storefront: storefront)
    let request = MusicDataRequest(urlRequest: URLRequest(url: url))
    let response = try await request.response()
    
    return try JSONDecoder().decode(Genres.self, from: response.data)
  }

  internal static func topGenresURL(storefront: String) throws -> URL {
    var components = AppleMusicURLComponents()
    components.path = "catalog/\(storefront)/genres"

    guard let url = components.url else {
      throw URLError(.badURL)
    }

    return url
  }
}

public extension MCatalog {
  /// Fetch all genres from the Apple Music catalog across all Apple Music storefronts.
  ///
  /// - Returns: Unique `Genres` from all storefronts.
  static func allGenres() async throws -> Genres {
    try await withThrowingTaskGroup(of: Genres.self) { group in
      let storefronts = try await MCatalog.storefronts().map { $0.id }
      var allGenres: Set<Genre> = []

      for storefront in storefronts {
        group.addTask {
          var components = AppleMusicURLComponents()
          components.path = "catalog/\(storefront)/genres"

          guard let url = components.url else {
            throw URLError(.badURL)
          }

          let request = MusicDataRequest(urlRequest: .init(url: url))
          let response = try await request.response()

          return try JSONDecoder().decode(Genres.self, from: response.data)
        }
      }

      for try await genres in group {
        for genre in genres {
          if allGenres.contains(where: { $0.id == genre.id && $0.name == $0.name }) {
            // Duplicate. Ignore
          } else {
            allGenres.insert(genre)
          }
        }
      }

      return MusicItemCollection(allGenres)
    }
  }
}

public extension MCatalog {
  /// Fetches the list of station genres available in the current country's storefront from Apple Music catalog.
  ///
  /// - Returns: `StationGenres` representing the list of station genres available in the current country's storefront.
  static func stationGenres() async throws -> StationGenres {
    let storefront = try await MusicDataRequest.currentCountryCode
    let url = try stationGenresURL(storefront: storefront)

    let request = MusicDataRequest(urlRequest: URLRequest(url: url))
    let response = try await request.response()

    let stationsGenres = try JSONDecoder().decode(StationGenres.self, from: response.data)

    return stationsGenres
  }

  /// Fetches the list of station genres available in the current country's storefront from Apple Music catalog.
  ///
  /// - Returns: `StationGenres` representing the list of station genres available in the current country's storefront.
  static func stationGenres(for storefront: StorefrontsData.Storefront) async throws -> StationGenres {
    let url = try stationGenresURL(storefront: storefront.id)
    let request = MusicDataRequest(urlRequest: URLRequest(url: url))
    let response = try await request.response()

    let stationsGenres = try JSONDecoder().decode(StationGenres.self, from: response.data)

    return stationsGenres
  }

  internal static func stationGenresURL(storefront: String) throws -> URL {
    var components = AppleMusicURLComponents()
    components.path = "catalog/\(storefront)/station-genres"

    guard let url = components.url else {
      throw URLError(.badURL)
    }

    return url
  }
}
