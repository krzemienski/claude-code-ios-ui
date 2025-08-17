//
//  CursorTabViewController.swift
//  ClaudeCodeUI
//
//  Created on 2025-01-16.
//

import UIKit
import SwiftUI

// MARK: - Cursor Tab View Controller
public class CursorTabViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel = CursorViewModel()
    private var hostingController: UIHostingController<CursorMainView>?
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Cursor"
        view.backgroundColor = CyberpunkTheme.background
        
        setupSwiftUIView()
        applyTheme()
        
        // Load initial data
        Task {
            await viewModel.loadAllData()
        }
    }
    
    // MARK: - Setup
    private func setupSwiftUIView() {
        // Create SwiftUI view with view model
        let cursorView = CursorMainView(viewModel: viewModel)
        
        // Create hosting controller
        let hostingController = UIHostingController(rootView: cursorView)
        self.hostingController = hostingController
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Set background color
        hostingController.view.backgroundColor = .clear
    }
    
    private func applyTheme() {
        // Configure navigation bar
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = CyberpunkTheme.background
        navigationController?.navigationBar.tintColor = CyberpunkTheme.primaryCyan
        
        // Navigation bar title attributes
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: CyberpunkTheme.textPrimary,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: CyberpunkTheme.textPrimary,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        
        // Add refresh button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )
    }
    
    // MARK: - Actions
    @objc private func refreshTapped() {
        Task {
            await viewModel.refresh()
        }
    }
}

// MARK: - SwiftUI Main View
struct CursorMainView: View {
    @ObservedObject var viewModel: CursorViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Tab Selector
                CursorTabSelector(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Content
                TabView(selection: $selectedTab) {
                    CursorConfigurationView(viewModel: viewModel)
                        .tag(0)
                    
                    CursorMCPServersView(viewModel: viewModel)
                        .tag(1)
                    
                    CursorSessionsView(viewModel: viewModel)
                        .tag(2)
                    
                    CursorSettingsView(viewModel: viewModel)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                LoadingOverlay()
            }
            
            // Message Overlays
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    MessageBanner(message: errorMessage, type: .error)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                if let successMessage = viewModel.successMessage {
                    MessageBanner(message: successMessage, type: .success)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                Spacer()
            }
            .animation(.spring(), value: viewModel.errorMessage)
            .animation(.spring(), value: viewModel.successMessage)
        }
    }
}

// MARK: - Tab Selector
struct CursorTabSelector: View {
    @Binding var selectedTab: Int
    
    let tabs = ["Config", "MCP", "Sessions", "Settings"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TabButton(
                    title: tabs[index],
                    isSelected: selectedTab == index,
                    action: { selectedTab = index }
                )
            }
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .black : Color(red: 0, green: 0.85, blue: 1))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    isSelected ?
                    LinearGradient(
                        colors: [Color(red: 0, green: 0.85, blue: 1), Color(red: 0, green: 0.65, blue: 0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : nil
                )
                .cornerRadius(10)
        }
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0, green: 0.85, blue: 1)))
                    .scaleEffect(1.5)
                
                Text("Loading...")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 0, green: 0.85, blue: 1).opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Message Banner
struct MessageBanner: View {
    let message: String
    let type: MessageType
    
    enum MessageType {
        case success
        case error
        
        var color: Color {
            switch self {
            case .success: return Color.green
            case .error: return Color(red: 1, green: 0, blue: 0.43)
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            Text(message)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(2)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
}