//
//  SearchFiltersView.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-17.
//

import SwiftUI

// MARK: - Search History Item
struct SearchHistoryItem {
    let query: String
    let fileTypes: [SearchFileType]
    let dateRange: DateRange
    let timestamp: Date
    let resultCount: Int
    
    init(query: String, fileTypes: [SearchFileType] = [], dateRange: DateRange = .anytime, timestamp: Date = Date(), resultCount: Int = 0) {
        self.query = query
        self.fileTypes = fileTypes
        self.dateRange = dateRange
        self.timestamp = timestamp
        self.resultCount = resultCount
    }
}

struct SearchFiltersView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Binding var isPresented: Bool
    @State private var selectedDateRange = DateRange.anytime
    @State private var customStartDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 1 week ago
    @State private var customEndDate = Date()
    
    var body: some View {
        NavigationView {
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // File Types Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("File Types", systemImage: "doc.text")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(CyberpunkTheme.primaryText))
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(FileType.allCases, id: \.self) { fileType in
                                    FileTypeToggle(
                                        fileType: fileType,
                                        isSelected: false // Will bind to viewModel
                                    )
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color(CyberpunkTheme.border))
                        
                        // Search Options Section
                        VStack(alignment: .leading, spacing: 16) {
                            Label("Search Options", systemImage: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(CyberpunkTheme.primaryText))
                            
                            // Regex Toggle
                            ToggleRow(
                                title: "Regular Expression",
                                icon: "textformat.123",
                                isOn: $viewModel.regexEnabled,
                                description: "Use regex patterns in search"
                            )
                            
                            // Case Sensitive Toggle
                            ToggleRow(
                                title: "Case Sensitive",
                                icon: "textformat.size",
                                isOn: $viewModel.caseSensitive,
                                description: "Match exact letter case"
                            )
                            
                            // Whole Word Toggle
                            ToggleRow(
                                title: "Whole Word",
                                icon: "textformat",
                                isOn: $viewModel.wholeWord,
                                description: "Match complete words only"
                            )
                        }
                        
                        Divider()
                            .background(Color(CyberpunkTheme.border))
                        
                        // Date Range Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Modified Date", systemImage: "calendar")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(CyberpunkTheme.primaryText))
                            
                            Picker("Date Range", selection: $selectedDateRange) {
                                ForEach(DateRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            if selectedDateRange == .custom {
                                VStack(spacing: 12) {
                                    DatePicker(
                                        "From",
                                        selection: $customStartDate,
                                        displayedComponents: .date
                                    )
                                    .foregroundColor(Color(CyberpunkTheme.secondaryText))
                                    
                                    DatePicker(
                                        "To",
                                        selection: $customEndDate,
                                        displayedComponents: .date
                                    )
                                    .foregroundColor(Color(CyberpunkTheme.secondaryText))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(CyberpunkTheme.surface))
                                )
                            }
                        }
                        
                        Divider()
                            .background(Color(CyberpunkTheme.border))
                        
                        // Search History Section
                        if !viewModel.searchHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("Search History", systemImage: "clock.arrow.circlepath")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(CyberpunkTheme.primaryText))
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.clearSearchHistory()
                                    }) {
                                        Text("Clear")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(CyberpunkTheme.warning))
                                    }
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(viewModel.searchHistory.prefix(10)) { item in
                                            SearchHistoryChip(item: item) {
                                                // Apply search from history
                                                applyHistoryItem(item)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                    .foregroundColor(Color(CyberpunkTheme.warning))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                }
            }
        }
    }
    
    private func resetFilters() {
        viewModel.$regexEnabled.wrappedValue = false
        viewModel.$caseSensitive.wrappedValue = false
        viewModel.$wholeWord.wrappedValue = false
        selectedDateRange = .anytime
    }
    
    private func applyHistoryItem(_ item: SearchHistoryItem) {
        // This would trigger a new search with the history item's parameters
        isPresented = false
    }
}

struct FileTypeToggle: View {
    let fileType: SearchFileType
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: fileType.icon)
                .font(.system(size: 14))
            Text(fileType.rawValue)
                .font(.system(size: 14))
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(CyberpunkTheme.primaryCyan))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isSelected ?
                    Color(CyberpunkTheme.primaryCyan).opacity(0.1) :
                    Color(CyberpunkTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
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
}

struct ToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(CyberpunkTheme.primaryCyan))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(CyberpunkTheme.primaryText))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(Color(CyberpunkTheme.tertiaryText))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(CyberpunkTheme.primaryCyan))
        }
        .padding(.vertical, 4)
    }
}

struct SearchHistoryChip: View {
    let item: SearchHistoryItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.query)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("\(item.resultCount) results")
                    Text("•")
                    Text(item.timestamp, style: .relative)
                }
                .font(.system(size: 10))
                .foregroundColor(Color(CyberpunkTheme.tertiaryText))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(CyberpunkTheme.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(CyberpunkTheme.border), lineWidth: 1)
                    )
            )
            .foregroundColor(Color(CyberpunkTheme.secondaryText))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum DateRange: String, CaseIterable {
    case anytime = "Any Time"
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case custom = "Custom"
}