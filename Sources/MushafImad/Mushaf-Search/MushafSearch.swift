//
//  Mushaf.swift
//  MushafImad
//
//  Created by Ahmad on 22/02/2026.
//
import SwiftUI

struct SearchRow: Identifiable {
    let id = UUID()
    let chapter: Chapter?
    let verse: Verse?
}

@MainActor
class MushafSearchViewModel: ObservableObject {
    @Published var searchResults: [SearchRow] = []
    @Published var query: String = ""
    private var service: RealmService

    init(service: RealmService = RealmService.shared) {
        self.service = service
    }

    func searchChaptersAndVerses() async {
        guard query.count != 0 else { return }

        let chapters = service.searchChapters(query: query)
//        let verses = service.searchVerses(query: query)

        var rows: [SearchRow] = []
        rows.append(contentsOf: chapters.map { SearchRow(chapter: $0, verse: nil) })
//        rows.append(contentsOf: verses.map { SearchRow(chapter: nil, verse: $0) })

        // Optionally: sort or prioritize chapters vs verses here
        searchResults = rows
    }
}

public struct MushafSearch: View {
    @StateObject private var viewModel = MushafSearchViewModel()

    public init() {}

    public var body: some View {
        NavigationView {
            List(viewModel.searchResults, id: \.id) { row in
                if let chapter = row.chapter {
                    ChapterResultRow(chapter: chapter)
                } else if let verse = row.verse {
                    VerseResultRow(verse: verse)
                } else {
                    EmptyView()
                }
            }
            .searchable(text: $viewModel.query, prompt: "Search Al-Baqarah, Al-Hamdu...")
            .task(id: viewModel.query) {
                await viewModel.searchChaptersAndVerses()
            }
        }
    }
}

struct VerseResultRow: View {
    let verse: Verse

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(verse.text)
                .font(.body)
                .lineLimit(2)
            HStack {
                if let ch = verse.chapter?.title {
                    Text(ch)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("#\(verse.number)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ChapterResultRow: View {
    let chapter: Chapter
    @State private var navbarHidden: Bool = true

    var body: some View {
        NavigationLink {
            MushafView(initialPage: chapter.startPage, onPageTap: {
                withAnimation {
                    navbarHidden.toggle()
                }
            })
            .toolbar(navbarHidden ? .hidden : .visible, for: .navigationBar)
        } label: {
            HStack {
                Text(chapter.title)
                    .font(.body)
                Spacer()
                Text("Chapter")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
