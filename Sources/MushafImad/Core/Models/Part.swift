//
//  Part.swift
//  MushafImad
//
//  Created by Ibrahim Qraiqe on 30/10/2025.
//

import Foundation
import RealmSwift

public final class Part: Object {
    @Persisted public var identifier: Int = 0
    @Persisted public var number: Int = 0
    @Persisted public var arabicTitle: String = ""
    @Persisted public var englishTitle: String = ""
    @Persisted public var chapters = List<Chapter>()
    @Persisted public var quarters = List<Quarter>()
    @Persisted public var verses = List<Verse>()
    
    @objc nonisolated override public class func primaryKey() -> String? {
        return "identifier"
    }
    
    @objc nonisolated override public class func indexedProperties() -> [String] {
        return ["number"]
    }
}

#if DEBUG
extension Part {
    /// Create a Part and attach the chapter and verse
    @MainActor
    static func makeMock(chapter: Chapter? = nil,
                                verse: Verse = .mock,
                                page: Page = .mock) -> Part {

		var resolvedChapter: Chapter = chapter ?? Chapter.makeMockFatiha()

        // Ensure verse is associated with the chapter and has a page
        verse.chapter = resolvedChapter
        verse.page1441 = page
        resolvedChapter.verses.append(verse)
        
        // Create a Part and attach the chapter and verse
        let part = Part()
        part.identifier = 1
        part.number = 1
        part.arabicTitle = "الجزء الأول"
        part.englishTitle = "Part One"
        part.chapters.append(resolvedChapter)
        part.verses.append(verse)
        return part
    }
}
#endif
