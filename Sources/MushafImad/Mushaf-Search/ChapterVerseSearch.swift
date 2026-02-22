//
//  SUrahVerseSearch.swift
//  MushafImad
//
//  Created by Ahmad on 22/02/2026.
//
import SwiftUI

@MainActor
class SurahVerseSearchViewModel: ObservableObject {
    @Published var suras: [Chapter] = []
    private var service: RealmService

    init(service: RealmService = RealmService.shared) {
        self.service = service
    }

    func getAllChapters() {}
}

public struct ChapterVerseSearch: View {
    @StateObject private var viewModel = SurahVerseSearchViewModel()

    public init() {}

    public var body: some View {
        NavigationView {
            List(viewModel.suras) { sura in
                Text(sura.title)
            }
            .task {
                await viewModel.getAllChapters()
            }
        }
    }
}
