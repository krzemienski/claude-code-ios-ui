//
//  ChatTableViewHandler.swift
//  ClaudeCodeUI
//
//  Created by Refactoring on 2025-01-21.
//

import UIKit

// MARK: - Chat Table View Handler

class ChatTableViewHandler: NSObject {
    
    // MARK: - Properties
    
    weak var tableView: UITableView?
    weak var viewController: UIViewController?
    private let viewModel: ChatViewModel
    private let streamingHandler: StreamingMessageHandler
    
    // Prefetching state
    private var isLoadingMore = false
    private let prefetchThreshold = 10
    
    // MARK: - Initialization
    
    init(tableView: UITableView, viewModel: ChatViewModel, streamingHandler: StreamingMessageHandler) {
        self.tableView = tableView
        self.viewModel = viewModel
        self.streamingHandler = streamingHandler
        super.init()
        
        setupTableView()
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.prefetchDataSource = self
        
        // Register cell types
        tableView?.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        
        // Configure table view
        tableView?.estimatedRowHeight = 100
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.keyboardDismissMode = .interactive
        tableView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView?.separatorStyle = .none
        tableView?.backgroundColor = .clear
    }
    
    // MARK: - Public Methods
    
    func reloadData() {
        tableView?.reloadData()
    }
    
    func insertMessage(at index: Int) {
        tableView?.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
    }
    
    func reloadMessage(at index: Int) {
        tableView?.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
    
    func scrollToBottom(animated: Bool = true) {
        guard let tableView = tableView,
              viewModel.messages.count > 0 else { return }
        
        let indexPath = IndexPath(row: viewModel.messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    func isNearBottom() -> Bool {
        guard let tableView = tableView else { return true }
        
        let contentHeight = tableView.contentSize.height
        let frameHeight = tableView.frame.height
        let contentOffsetY = tableView.contentOffset.y
        
        return contentOffsetY >= (contentHeight - frameHeight - 100)
    }
}

// MARK: - UITableViewDataSource

extension ChatTableViewHandler: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.messages.count else {
            return UITableViewCell()
        }
        
        let message = viewModel.messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ChatMessageCell.identifier,
            for: indexPath
        ) as! ChatMessageCell
        
        cell.configure(with: message)
        
        // Mark message as read when displayed
        if !message.isUser && message.status != .read {
            Task { @MainActor in
                viewModel.updateMessageStatus(message.id, status: .read)
            }
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatTableViewHandler: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Swipe Actions for Message Retry
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < viewModel.messages.count else { return nil }
        
        let message = viewModel.messages[indexPath.row]
        
        // Only show retry for failed user messages
        guard message.isUser && message.status == .failed else { return nil }
        
        let retryAction = UIContextualAction(style: .normal, title: "Retry") { [weak self] _, _, completion in
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            
            // Retry the message
            self?.viewModel.retryMessage(message)
            
            // Reload the cell to update status
            tableView.reloadRows(at: [indexPath], with: .automatic)
            
            completion(true)
        }
        
        retryAction.backgroundColor = CyberpunkTheme.warning
        retryAction.image = UIImage(systemName: "arrow.clockwise")
        
        return UISwipeActionsConfiguration(actions: [retryAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < viewModel.messages.count else { return nil }
        
        let message = viewModel.messages[indexPath.row]
        
        // Copy action for all messages
        let copyAction = UIContextualAction(style: .normal, title: "Copy") { _, _, completion in
            UIPasteboard.general.string = message.content
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            
            completion(true)
        }
        
        copyAction.backgroundColor = CyberpunkTheme.primaryCyan
        copyAction.image = UIImage(systemName: "doc.on.doc")
        
        return UISwipeActionsConfiguration(actions: [copyAction])
    }
}

// MARK: - UITableViewDataSourcePrefetching

extension ChatTableViewHandler: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Check if we need to load more messages
        for indexPath in indexPaths {
            if indexPath.row < prefetchThreshold && !isLoadingMore && viewModel.hasMoreMessages {
                loadMoreMessages()
                break
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        // Cancel any ongoing prefetch operations if needed
    }
    
    // MARK: - Private Methods
    
    private func loadMoreMessages() {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        
        Task { @MainActor in
            let currentCount = viewModel.messages.count
            let newMessages = await viewModel.loadMoreMessages(offset: currentCount)
            
            if !newMessages.isEmpty {
                // Calculate index paths for new messages
                let indexPaths = (0..<newMessages.count).map { IndexPath(row: $0, section: 0) }
                
                // Insert rows at the top
                tableView?.insertRows(at: indexPaths, with: .automatic)
            }
            
            isLoadingMore = false
        }
    }
}