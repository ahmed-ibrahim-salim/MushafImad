//
//  Quarter.swift
//  MushafImad
//
//  Created by Ibrahim Qraiqe on 30/10/2025.
//

import Foundation
import RealmSwift

public final class Quarter: Object {
    @Persisted public var identifier: Int = 0
    @Persisted public var hizbNumber: Int = 0
    @Persisted public var hizbFraction: Int = 0  // 0=start, 1=quarter, 2=half, 3=three-quarters
    @Persisted public var arabicTitle: String = ""
    @Persisted public var englishTitle: String = ""
    @Persisted public var part: Part?
    @Persisted public var verses = List<Verse>()
    
    @objc nonisolated override public class func primaryKey() -> String? {
        return "identifier"
    }
    
    @objc nonisolated override public class func indexedProperties() -> [String] {
        return ["hizbNumber"]
    }
    
    // Helper computed property for UI
    public var hizbQuarterProgress: HizbQuarterProgress? {
        switch hizbFraction {
        case 1: return .quarter
        case 2: return .half
        case 3: return .threeQuarters
        default: return nil
        }
    }
}

#if DEBUG
extension Quarter {
    /// Creates a mock Quarter with associated Chapter, Verse, and Page for testing purposes.
    @MainActor
    static func makeMock(chapter: Chapter? = nil,
                                verse: Verse = .mock,
                                page: Page = .mock) -> Quarter {

        let resolvedChapter: Chapter = chapter ?? Chapter.makeMockFatiha()

		verse.chapter = resolvedChapter
        verse.page1441 = page
        resolvedChapter.verses.append(verse)
        
        // Create a Quarter and attach the verse
        let quarter = Quarter()
        quarter.identifier = 11
        quarter.hizbNumber = 2
        quarter.hizbFraction = 1
        quarter.arabicTitle = "الربع التجريبي"
        quarter.englishTitle = "Test Quarter"
        quarter.verses.append(verse)
        return quarter
    }
}
#endif
