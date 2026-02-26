import Foundation
import Testing
@testable import MushafImad

/// Tests for ChaptersDataCache to ensure caching logic works correctly and improves performance as expected.
@MainActor
struct ChaptersDataCacheTests {

    @Test
    func testInitialCacheIsEmpty() async {
        // Arrange
        let chaptersCache = ChaptersDataCache.shared
        defer { chaptersCache.clearCache() }
        
        // Act
        chaptersCache.setRealmService(RealmServiceStub())
        
        // Assert
        #expect(chaptersCache.allChapters.isEmpty)
        #expect(chaptersCache.allChaptersByPart.isEmpty)
        #expect(chaptersCache.allChaptersByHizb.isEmpty)
        #expect(chaptersCache.allChaptersByType.isEmpty)
        #expect(chaptersCache.isCached == false)
        #expect(chaptersCache.isPartsCached == false)
        #expect(chaptersCache.isHizbCached == false)
        #expect(chaptersCache.isTypeCached == false)
    }
    
    @Test
    func testLoadAndCachePopulatesChapters() async throws {
        // Arrange
        let chaptersCache = ChaptersDataCache.shared
        defer { chaptersCache.clearCache() }
        var onBatchLoadedCalled = false
        let onBatchLoaded: (Int) -> Void = {_ in
            onBatchLoadedCalled = true
        }
        
        // Act
        chaptersCache.setRealmService(RealmServiceStub())
        try await chaptersCache.loadAndCache(onBatchLoaded: onBatchLoaded)
        
        // Assert
        #expect(chaptersCache.allChapters.count == 1)
        #expect(chaptersCache.isCached == true)
        #expect(onBatchLoadedCalled == true)
    }

}

private class RealmServiceStub: RealmServiceProtocol {
    func fetchAllChaptersAsync() async throws -> [MushafImad.Chapter] {
        [Chapter.mock]
    }
    
    func fetchAllPartsAsync() async throws -> [MushafImad.Part] {
        []
    }
    
    func fetchAllQuartersAsync() async throws -> [MushafImad.Quarter] {
        []
    }
    
}

