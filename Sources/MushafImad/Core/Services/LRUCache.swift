import Foundation

/// Cache statistics for monitoring cache effectiveness
///
/// Contains metrics about cache performance including hit/miss ratios
public struct CacheStats: Sendable {
    /// Current number of items in the cache
    public let count: Int
    
    /// Total number of cache hits
    public let hits: Int
    
    /// Total number of cache misses
    public let misses: Int
    
    /// Hit ratio as a percentage (0-100)
    public var hitRatio: Double {
        let total = hits + misses
        guard total > 0 else { return 0 }
        return Double(hits) / Double(total) * 100
    }
}

// MARK: - Doubly Linked List Node

private final class LRUCacheNode<Key: Hashable, Value: AnyObject> {
    let key: Key
    var value: Value
    weak var prev: LRUCacheNode?
    var next: LRUCacheNode?
    
    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}

/// A thread-safe LRU (Least Recently Used) cache implementation
///
/// Uses a doubly linked list combined with a hash map to provide O(1) time complexity
/// for both lookups and insertions. The cache automatically evicts the least recently
/// used items when it reaches capacity.
///
/// - Note: This class is thread-safe and can be used concurrently from multiple threads.
/// - Important: The `Key` type must be `Hashable` and the `Value` type must be a class (reference type).
final class LRUCache<Key: Hashable, Value: AnyObject>: @unchecked Sendable {
    
    // MARK: - Properties
    
    let name: String
    private let lock = NSLock()
    
    // Head = Most Recently Used, Tail = Least Recently Used
    private var head: LRUCacheNode<Key, Value>?
    private var tail: LRUCacheNode<Key, Value>?
    
    // Hash map for O(1) lookup
    private var cache: [Key: LRUCacheNode<Key, Value>] = [:]
    
    // Statistics
    private var _count: Int = 0
    private var _hits: Int = 0
    private var _misses: Int = 0
    
    // MARK: - Public Properties
    
    /// Returns the current number of items in the cache.
    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return _count
    }
    
    /// Total number of cache hits recorded.
    var hits: Int {
        lock.lock()
        defer { lock.unlock() }
        return _hits
    }
    
    /// Total number of cache misses recorded.
    var misses: Int {
        lock.lock()
        defer { lock.unlock() }
        return _misses
    }
    
    /// Maximum number of items the cache can hold.
    let countLimit: Int
    
    // MARK: - Initialization
    
    /// Creates a new LRU cache with the specified capacity.
    ///
    /// - Parameters:
    ///   - name: A descriptive name for the cache instance (used for debugging/identification).
    ///   - countLimit: The maximum number of items the cache can hold. Defaults to 100.
    init(name: String, countLimit: Int = 100) {
        self.name = name
        self.countLimit = countLimit
    }
        
    // MARK: - Private Helper Methods
    
    /// Moves a node to the head of the doubly linked list (most recently used position).
    /// Assumes the caller holds the lock.
    /// - Parameter node: The node to promote to head.
    private func promoteToHead(_ node: LRUCacheNode<Key, Value>) {
        // No-op if already at head
        guard node.prev != nil else { return }
        
        // Unlink the node from its current position
        node.prev?.next = node.next
        if node.next == nil { tail = node.prev }
        else { node.next?.prev = node.prev }
        
        // Insert at head
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
    }
    
	// MARK: - Public Methods

    /// Retrieves the value associated with the specified key.
    ///
    /// This method performs an O(1) lookup and moves the accessed item to the
    /// most recently used position.
    ///
    /// - Parameter key: The key to look up in the cache.
    /// - Returns: The cached value if found, otherwise `nil`.
    ///
    /// - Note: Accessing an item counts as a cache hit, while a missing key counts as a cache miss.
    func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let node = cache[key] else {
            _misses += 1
            return nil
        }
        
        _hits += 1
        promoteToHead(node)
        return node.value
    }
    
    /// Stores a value in the cache with the specified key.
    ///
    /// If the key already exists, its value is updated and moved to the most
    /// recently used position. If the cache is at capacity, the least recently
    /// used item is evicted.
    ///
    /// - Parameters:
    ///   - value: The value to cache (must be a class/reference type).
    ///   - key: The key to associate with the value.
    func set(_ value: Value, forKey key: Key) {
        lock.lock()
        defer { lock.unlock() }

        if let existingNode = cache[key] {
            existingNode.value = value
            promoteToHead(existingNode)
            return
        }
        
        // Add new node at head
        let newNode = LRUCacheNode(key: key, value: value)
        newNode.next = head
        head?.prev = newNode
        head = newNode
        
        if tail == nil { tail = newNode }
        
        cache[key] = newNode
        _count += 1
        
        // Evict LRU if over capacity
        while _count > countLimit, let tailNode = tail {
            cache.removeValue(forKey: tailNode.key)
            tail = tailNode.prev
            tail?.next = nil
            _count -= 1
        }        
    }
    
    /// Checks whether the cache contains the specified key.
    ///
    /// - Parameter key: The key to check for.
    /// - Returns: `true` if the key exists in the cache, `false` otherwise.
    func contains(_ key: Key) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return cache[key] != nil
    }
    
    /// Removes the value associated with the specified key from the cache.
    ///
    /// If the key doesn't exist, this method does nothing.
    ///
    /// - Parameter key: The key to remove from the cache.
    func remove(_ key: Key) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let node = cache[key] else { return }
        
        if node.prev == nil {
       		head = node.next
		} else {
			node.prev?.next = node.next
		}
	
		if node.next == nil {
			tail = node.prev
		} else {
			node.next?.prev = node.prev
		}
        
        cache.removeValue(forKey: key)
        _count -= 1
    }
    
    /// Removes all items from the cache and resets statistics.
    ///
    /// After calling this method, the cache will be empty and all hit/miss
    /// counters will be reset to zero.
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        
        head = nil
        tail = nil
        cache.removeAll()
        _count = 0
        _hits = 0
        _misses = 0
    }
    
    /// Returns current cache statistics including count, hits, and misses.
    ///
    /// - Returns: A `CacheStats` struct containing current cache metrics.
    func getStats() -> CacheStats {
        lock.lock()
		defer { lock.unlock() }

        let stats = CacheStats(count: _count, hits: _hits, misses: _misses)
        return stats
    }
    
    /// Resets only the hit and miss counters to zero.
    ///
    /// This is useful when you want to measure cache performance over a
    /// specific time period without clearing the cached items.
    func resetStats() {
        lock.lock()
        defer { lock.unlock() }
        _hits = 0
        _misses = 0
    }
}
