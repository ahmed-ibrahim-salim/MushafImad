//
//  QuranDataCacheService.swift
//  MushafImad
//
//  Created by Ibrahim Qraiqe on 31/10/2025.
//

import Foundation
import RealmSwift

/// Service to cache Quran data from Realm for quick access
/// Uses custom LRUCache with eviction policies to limit memory usage.
@MainActor
public final class QuranDataCacheService {
    public static let shared = QuranDataCacheService()
    
    // MARK: - Cache Configuration
    
	/// Maximum number of verses pages to cache
    private static let maxCachedVerses = 1000

    /// Maximum number of pages to cache (headers)
    private static let maxCachedPages = 200
    
    /// Maximum number of chapters to cache
    private static let maxCachedChapters = 100
        
    /// Bounded Cache for verses indexed by page number
    private var cachedVerses: LRUCache<Int, NSArray>
    
    /// Bounded Cache for page header info indexed by page number
    private var cachedPageHeaders: LRUCache<Int, PageHeaderInfoWrapper>
    
    /// Bounded Cache for chapter verses indexed by chapter number
    private var cachedChapterVerses: LRUCache<Int, NSArray>
    
    private let realmService = RealmService.shared
    
    public init() {
        // Initialize bounded caches with configured limits
        // Memory limits: verses=20MB, headers=5MB, chapters=25MB
        cachedVerses = LRUCache(name: "verses", countLimit: Self.maxCachedVerses)
        cachedPageHeaders = LRUCache(name: "pageHeaders", countLimit: Self.maxCachedPages)
        cachedChapterVerses = LRUCache(name: "chapterVerses", countLimit: Self.maxCachedChapters)
    }
    
    // MARK: - Cache Management
    
    /// Pre-fetch and cache data for a specific page
    public func cachePageData(_ pageNumber: Int) async {
        // Cache verses for this page
        let verses = realmService.getVersesForPage(pageNumber)
        if !verses.isEmpty {
            cachedVerses.set(verses as NSArray, forKey: pageNumber)
        }
        
        // Cache page header
        if let headerInfo = realmService.getPageHeaderInfo(for: pageNumber) {
            cachedPageHeaders.set(PageHeaderInfoWrapper(info: headerInfo), forKey: pageNumber)
        }
        
        // Cache chapter verses for chapters on this page
        let chapters = realmService.getChaptersOnPage(pageNumber)
        for chapter in chapters {
            if cachedChapterVerses.get(chapter.number) == nil {
                let chapterVerses = realmService.getVersesForChapter(chapter.number)
                if !chapterVerses.isEmpty {
                    cachedChapterVerses.set(chapterVerses as NSArray, forKey: chapter.number)
                }
            }
        }
    }
    
    /// Pre-fetch and cache data for a range of pages (e.g., for a chapter)
    public func cachePageRange(_ pageRange: ClosedRange<Int>) async {
        for pageNumber in pageRange {
            await cachePageData(pageNumber)
        }
    }
    
    /// Pre-fetch and cache data for a specific chapter
    public func cacheChapterData(_ chapter: Chapter) async {
        // Cache chapter verses
        let verses = realmService.getVersesForChapter(chapter.number)
        if !verses.isEmpty {
            cachedChapterVerses.set(verses as NSArray, forKey: chapter.number)
        }
        
        // Cache all pages in this chapter
        await cachePageRange(chapter.startPage...chapter.endPage)
    }
    
    // MARK: - Cache Retrieval
    
    /// Get cached verses for a page (returns nil if not cached)
    public func getCachedVerses(forPage pageNumber: Int) -> [Verse]? {
        guard let cached = cachedVerses.get(pageNumber) as? [Verse] else {
            return nil
        }
        return cached
    }
    
    /// Get cached page header (returns nil if not cached)
    public func getCachedPageHeader(forPage pageNumber: Int) -> PageHeaderInfo? {
        return cachedPageHeaders.get(pageNumber)?.info
    }
    
    /// Get cached verses for a chapter (returns nil if not cached)
    public func getCachedChapterVerses(forChapter chapterNumber: Int) -> [Verse]? {
        guard let cached = cachedChapterVerses.get(chapterNumber) as? [Verse] else {
            return nil
        }
        return cached
    }
    
    /// Check if page data is cached
    public func isPageCached(_ pageNumber: Int) -> Bool {
        return cachedVerses.contains(pageNumber) && cachedPageHeaders.contains(pageNumber)
    }
    
    /// Check if chapter data is fully cached
    public func isChapterCached(_ chapter: Chapter) -> Bool {
        guard cachedChapterVerses.get(chapter.number) != nil else { return false }
        
        // Check if all pages are cached
        for pageNumber in chapter.startPage...chapter.endPage {
            if !isPageCached(pageNumber) {
                return false
            }
        }
        return true
    }
    
    // MARK: - Cache Management
    
    /// Clear cached data for a specific page
    public func clearPageCache(_ pageNumber: Int) {
        cachedVerses.remove(pageNumber)
        cachedPageHeaders.remove(pageNumber)
    }
    
    /// Clear cached data for a chapter
    public func clearChapterCache(_ chapterNumber: Int) {
        cachedChapterVerses.remove(chapterNumber)
    }
    
    /// Clear all cached data
    public func clearAllCache() {
        cachedVerses.removeAll()
        cachedPageHeaders.removeAll()
        cachedChapterVerses.removeAll()
    }
    
    /// Get cache statistics for all caches
    public func getCacheStats() -> CombinedCacheStats {
        return CombinedCacheStats(
            verses: cachedVerses.getStats(),
            pageHeaders: cachedPageHeaders.getStats(),
            chapterVerses: cachedChapterVerses.getStats()
        )
    }
}

// MARK: - Supporting Types

/// Combined cache statistics for all caches
public struct CombinedCacheStats {
    public let verses: CacheStats
    public let pageHeaders: CacheStats
    public let chapterVerses: CacheStats
    
    public var totalItems: Int {
        return verses.count + pageHeaders.count + chapterVerses.count
    }
    
    public var totalHits: Int {
        return verses.hits + pageHeaders.hits + chapterVerses.hits
    }
    
    public var totalMisses: Int {
        return verses.misses + pageHeaders.misses + chapterVerses.misses
    }
    
    public var overallHitRatio: Double {
        let total = totalHits + totalMisses
        guard total > 0 else { return 0 }
        return Double(totalHits) / Double(total) * 100
    }
}

// MARK: - Helper Wrapper

private class PageHeaderInfoWrapper: NSObject {
    let info: PageHeaderInfo
    
    init(info: PageHeaderInfo) {
        self.info = info
        super.init()
    }
}
