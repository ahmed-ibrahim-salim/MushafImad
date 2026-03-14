import Foundation
import Testing
@testable import MushafImad

struct LRUCacheTests {
        
    @Test
    func testSetStoresValue() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "test", countLimit: 5)
        
        // Act
        cache.set("Hello" as NSString, forKey: "greeting")
        let value = cache.get("greeting")
        
        // Assert
        #expect(value == "Hello" as NSString)
    }
    
    @Test
    func testSetIncrementsCount() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "count", countLimit: 5)
        
        // Act & Assert
        #expect(cache.count == 0)
        cache.set("A" as NSString, forKey: "1")
        #expect(cache.count == 1)
        cache.set("B" as NSString, forKey: "2")
        #expect(cache.count == 2)
    }
    
    @Test
    func testGetReturnsNilForMissingKey() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "miss", countLimit: 5)
        
        // Act
        let value = cache.get("nonexistent")
        
        // Assert
        #expect(value == nil)
    }
    
    @Test
    func testCacheMissIncrementsMissCount() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "missStat", countLimit: 5)
        
        // Act
        _ = cache.get("nonexistent")
        let stats = cache.getStats()
        
        // Assert
        #expect(stats.misses == 1)
    }
    
    @Test
    func testCacheHitIncrementsHitCount() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "hitStat", countLimit: 5)
        
        // Act
        cache.set("Value" as NSString, forKey: "key1")
        _ = cache.get("key1")
        let stats = cache.getStats()
        
        // Assert
        #expect(stats.hits == 1)
    }
    
    @Test
    func testContainsReturnsTrueForExistingKey() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "contains", countLimit: 5)
        
        // Act
        cache.set("test" as NSString, forKey: "present")
        
        // Assert
        #expect(cache.contains("present") == true)
    }
    
    @Test
    func testContainsReturnsFalseForMissingKey() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "contains2", countLimit: 5)
        
        // Act & Assert
        #expect(cache.contains("absent") == false)
    }
    
    @Test
    func testRemoveDeletesKey() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "remove", countLimit: 5)
        cache.set("value" as NSString, forKey: "key1")
        
        // Act
        cache.remove("key1")
        
        // Assert
        #expect(cache.contains("key1") == false)
    }
    
    @Test
    func testRemoveDecrementsCount() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "removeCount", countLimit: 5)
        cache.set("value" as NSString, forKey: "key1")
        
        // Act & Assert
        #expect(cache.count == 1)
        cache.remove("key1")
        #expect(cache.count == 0)
    }
    
    @Test
    func testRemoveAllClearsCache() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "clear", countLimit: 5)
        cache.set("A" as NSString, forKey: "1")
        cache.set("B" as NSString, forKey: "2")
        
        // Act
        cache.removeAll()
        
        // Assert
        #expect(cache.count == 0)
    }
    
    @Test
    func testRemoveAllResetsStats() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "clearStats", countLimit: 5)
        cache.set("A" as NSString, forKey: "1")
        _ = cache.get("1")
        
        // Act
        cache.removeAll()
        let stats = cache.getStats()
        
        // Assert
        #expect(stats.hits == 0)
        #expect(stats.misses == 0)
    }
    
    @Test
    func testResetStatsClearsHitsAndMisses() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "reset", countLimit: 5)
        cache.set("val" as NSString, forKey: "k")
        _ = cache.get("k")
        _ = cache.get("nonexistent")
        
        // Act
        cache.resetStats()
        let stats = cache.getStats()
        
        // Assert
        #expect(stats.hits == 0)
        #expect(stats.misses == 0)
    }
    
    @Test
    func testResetStatsPreservesCount() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "resetCount", countLimit: 5)
        cache.set("val" as NSString, forKey: "k")
        
        // Act
        cache.resetStats()
        
        // Assert
        #expect(cache.count == 1)
    }
    
    @Test
    func testHitRatioCalculation() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "ratio", countLimit: 10)
        
        // Act
        cache.set("v1" as NSString, forKey: "k1")
        _ = cache.get("k1")  // Hit
        _ = cache.get("k1")  // Hit
        _ = cache.get("k2")  // Miss
        _ = cache.get("k1")  // Hit (3 hits / 4 total = 75%)
        let stats = cache.getStats()
        
        // Assert
        #expect(stats.hitRatio == 75.0)
    }
        
    @Test
    func testEvictionRemovesLeastRecentlyUsed() {
        // Arrange
        // Core LRU behavior: oldest accessed item should be evicted
        let cache = LRUCache<String, NSString>(name: "evict", countLimit: 2)
        
        // Act
        cache.set("A" as NSString, forKey: "key1")  // Oldest
        cache.set("B" as NSString, forKey: "key2")  // Second oldest
        cache.set("C" as NSString, forKey: "key3")  // Newest - triggers eviction
        
        // Assert
        // key1 should be evicted (it was least recently used)
        #expect(cache.contains("key1") == false)
        #expect(cache.contains("key2") == true)
        #expect(cache.contains("key3") == true)
        #expect(cache.count == 2)
    }
    
    @Test
    func testAccessingItemMovesItToMostRecentlyUsed() {
        // Arrange
        // When we get() an item, it should become MRU
        let cache = LRUCache<String, NSString>(name: "access", countLimit: 2)
        
        // Act
        cache.set("A" as NSString, forKey: "key1")  // Oldest
        cache.set("B" as NSString, forKey: "key2")  // MRU
        _ = cache.get("key1")  // Access key1 - now it's MRU
        cache.set("C" as NSString, forKey: "key3")  // Should evict key2, not key1
        
        // Assert
        // key1 should still be there (was accessed recently)
        #expect(cache.contains("key1") == true)
        // key2 should be evicted (was LRU before key1 was accessed)
        #expect(cache.contains("key2") == false)
        #expect(cache.contains("key3") == true)
    }
    
    @Test
    func testUpdatingExistingKeyMovesItToMRU() {
        // Arrange
        // Setting a value for existing key should update and move to MRU
        let cache = LRUCache<String, NSString>(name: "update", countLimit: 2)
        
        // Act
        cache.set("A" as NSString, forKey: "key1")  // Oldest
        cache.set("B" as NSString, forKey: "key2")  // MRU
        cache.set("A_updated" as NSString, forKey: "key1")  // Update key1 - now MRU
        cache.set("C" as NSString, forKey: "key3")  // Should evict key2
        
        // Assert
        #expect(cache.contains("key1") == true)
        #expect(cache.contains("key2") == false)  // Evicted
        #expect(cache.contains("key3") == true)
    }
    
    @Test
    func testGetUpdatesAccessOrder() {
        // Arrange
        // Multiple gets should keep item as MRU
        let cache = LRUCache<String, NSString>(name: "getOrder", countLimit: 2)
        
        // Act
        cache.set("A" as NSString, forKey: "key1")
        cache.set("B" as NSString, forKey: "key2")
        _ = cache.get("key1")  // Access key1
        _ = cache.get("key1")  // Access key1 again
        cache.set("C" as NSString, forKey: "key3")
        
        // Assert
        // key1 should survive (most recently accessed)
        #expect(cache.contains("key1") == true)
        #expect(cache.contains("key2") == false)
    }
    
    @Test
    func testEvictionOrderWithSequentialInserts() {
        // Arrange
        // Fill cache to capacity, then add one more
        let cache = LRUCache<String, NSString>(name: "seq", countLimit: 3)
        
        // Act
        cache.set("1" as NSString, forKey: "a")
        cache.set("2" as NSString, forKey: "b")
        cache.set("3" as NSString, forKey: "c")
        #expect(cache.count == 3)
        
        cache.set("4" as NSString, forKey: "d")
        
        // Assert
        #expect(cache.count == 3)
        #expect(cache.contains("a") == false)  // First item evicted
        #expect(cache.contains("b") == true)
        #expect(cache.contains("c") == true)
        #expect(cache.contains("d") == true)
    }
    
    @Test
    func testEmptyCacheCountIsZero() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "empty", countLimit: 5)
        
        // Assert
        #expect(cache.count == 0)
    }
    
    @Test
    func testUpdateValueDoesNotChangeCount() {
        // Arrange
        let cache = LRUCache<String, NSString>(name: "updateCount", countLimit: 5)
        
        // Act
        cache.set("Original" as NSString, forKey: "key")
        #expect(cache.count == 1)
        cache.set("Updated" as NSString, forKey: "key")
        
        // Assert
        #expect(cache.count == 1)  // Count unchanged
    }
}
