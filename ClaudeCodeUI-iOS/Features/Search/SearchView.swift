//
//  SearchView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @State private var searchText = ""
    @State private var selectedScope = SearchScope.all
    @State private var selectedFileTypes: Set<SearchFileType> = []
    @State private var showingFilters = false
    
    init(viewModel: SearchViewModel? = nil) {
        self.viewModel = viewModel ?? SearchViewModel()
    }
    
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Cyberpunk background
            LinearGradient(
                colors: [
                    Color(UIColor(hex: "#0A0A0F")!),
                    Color(UIColor(hex: "#1A1A2E")!)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search header
                searchHeader
                
                // Filters bar
                if showingFilters {
                    filtersBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Results
                if viewModel.isSearching {
                    loadingView
                } else if !searchText.isEmpty && viewModel.results.isEmpty {
                    emptyResultsView
                } else if !viewModel.results.isEmpty {
                    resultsView
                } else {
                    idleView
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isSearchFieldFocused = true
        }
    }
    
    private var searchHeader: some View {
        VStack(spacing: 12) {
            // Title and filter button
            HStack {
                Text("Search")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(CyberpunkTheme.primaryText))
                
                Spacer()
                
                Button(action: { withAnimation { showingFilters.toggle() } }) {
                    Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 24))
                        .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                        .shadow(color: Color(CyberpunkTheme.primaryCyan).opacity(0.6), radius: 4)
                }
            }
            
            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(CyberpunkTheme.tertiaryText))
                
                TextField("Search in project...", text: $searchText)
                    .foregroundColor(Color(CyberpunkTheme.primaryText))
                    .accentColor(Color(CyberpunkTheme.primaryCyan))
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button(action: { 
                        searchText = ""
                        viewModel.clearResults()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(CyberpunkTheme.tertiaryText))
                    }
                }
                
                Button(action: performSearch) {
                    Text("Search")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(CyberpunkTheme.primaryCyan),
                                    Color(CyberpunkTheme.gradientBlue)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                }
                .disabled(searchText.isEmpty)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(CyberpunkTheme.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSearchFieldFocused ?
                                Color(CyberpunkTheme.primaryCyan).opacity(0.5) :
                                Color(CyberpunkTheme.border),
                                lineWidth: 1
                            )
                    )
            )
            
            // Scope selector
            Picker("Scope", selection: $selectedScope) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.top, 8)
        }
        .padding()
        .background(
            Color(CyberpunkTheme.surface)
                .opacity(0.3)
                .ignoresSafeArea(edges: .top)
        )
    }
    
    private var filtersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // File type filters
                ForEach(SearchFileType.allCases, id: \.self) { fileType in
                    FilterChip(
                        title: fileType.rawValue,
                        icon: fileType.icon,
                        isSelected: selectedFileTypes.contains(fileType)
                    ) {
                        if selectedFileTypes.contains(fileType) {
                            selectedFileTypes.remove(fileType)
                        } else {
                            selectedFileTypes.insert(fileType)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(
            Color(CyberpunkTheme.surface)
                .opacity(0.5)
        )
    }
    
    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Results summary
                HStack {
                    Text("\(viewModel.results.count) results found")
                        .font(.system(size: 14))
                        .foregroundColor(Color(CyberpunkTheme.secondaryText))
                    
                    Spacer()
                    
                    if viewModel.searchTime > 0 {
                        Text(String(format: "%.2fs", viewModel.searchTime))
                            .font(.system(size: 12))
                            .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Search results
                ForEach(viewModel.results) { result in
                    SearchResultRow(result: result, searchText: searchText)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(CyberpunkTheme.primaryCyan)))
                .scaleEffect(1.5)
            
            Text("Searching...")
                .font(.system(size: 16))
                .foregroundColor(Color(CyberpunkTheme.secondaryText))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(Color(CyberpunkTheme.tertiaryText))
            
            VStack(spacing: 8) {
                Text("No results found")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(CyberpunkTheme.primaryText))
                
                Text("Try different keywords or adjust filters")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.secondaryText))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var idleView: some View {
        VStack(spacing: 32) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 80))
                .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                .shadow(color: Color(CyberpunkTheme.primaryCyan).opacity(0.3), radius: 20)
            
            VStack(spacing: 16) {
                Text("Search Your Project")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(CyberpunkTheme.primaryText))
                
                Text("Find code, files, and content across your entire project")
                    .font(.system(size: 14))
                    .foregroundColor(Color(CyberpunkTheme.secondaryText))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Recent searches
            if !viewModel.recentSearches.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Searches")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(CyberpunkTheme.secondaryText))
                    
                    ForEach(viewModel.recentSearches, id: \.self) { search in
                        Button(action: {
                            searchText = search
                            performSearch()
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 12))
                                Text(search)
                                    .font(.system(size: 14))
                                Spacer()
                            }
                            .foregroundColor(Color(CyberpunkTheme.tertiaryText))
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(CyberpunkTheme.surface))
                )
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        viewModel.search(
            query: searchText,
            scope: selectedScope,
            fileTypes: selectedFileTypes.map { SearchFileType(rawValue: $0.rawValue) ?? .other }
        )
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        Color(CyberpunkTheme.primaryCyan).opacity(0.2) :
                        Color(CyberpunkTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                Color(CyberpunkTheme.primaryCyan) :
                                Color(CyberpunkTheme.border),
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(
                isSelected ?
                Color(CyberpunkTheme.primaryCyan) :
                Color(CyberpunkTheme.secondaryText)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SearchScopeView: String, CaseIterable {
    case all = "All"
    case code = "Code"
    case files = "Files"
    case comments = "Comments"
}

enum SearchFileType: String, CaseIterable {
    case swift = "Swift"
    case objectiveC = "Obj-C"
    case javascript = "JS"
    case typescript = "TS"
    case json = "JSON"
    case markdown = "MD"
    case xml = "XML"
    case yaml = "YAML"
    
    var icon: String {
        switch self {
        case .swift: return "swift"
        case .objectiveC: return "c.circle"
        case .javascript: return "curlybraces"
        case .typescript: return "t.circle"
        case .json: return "doc.text"
        case .markdown: return "doc.richtext"
        case .xml: return "chevron.left.slash.chevron.right"
        case .yaml: return "doc.plaintext"
        }
    }
}