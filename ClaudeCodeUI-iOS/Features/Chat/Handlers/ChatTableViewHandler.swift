//
//  ChatTableViewHandler.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-30.
//  Handles table view delegation and data source for chat messages
//

import UIKit
import Combine

// MARK: - ChatTableViewHandler

/// Manages table view data source and delegate responsibilities for chat
final class ChatTableViewHandler: NSObject {
    
    // MARK: - Properties
    
    weak var tableView: UITableView?
    weak var viewModel: ChatViewModel?
    weak var navigationDelegate: ChatNavigationDelegate?
    
    private var messages: [ChatMessage] = []
    private var isTyping = false
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private let estimatedRowHeight: CGFloat = 80
    private let typingIndicatorHeight: CGFloat = 50
    
    // MARK: - Initialization
    
    init(tableView: UITableView, viewModel: ChatViewModel) {
        self.tableView = tableView
        self.viewModel = viewModel
        super.init()
        
        setupTableView()
        Task { @MainActor in
            setupBindings()
        }
    }
    
    // MARK: - Setup
    
    private func setupTableView() {
        tableView?.delegate = self
        tableView?.dataSource = self
        tableView?.prefetchDataSource = self
        
        // Register cells
        tableView?.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
        tableView?.register(ChatTypingIndicatorCell.self, forCellReuseIdentifier: "ChatTypingIndicatorCell")
        tableView?.register(ChatDateHeaderView.self, forHeaderFooterViewReuseIdentifier: "ChatDateHeaderView")
        
        // Configure table view
        tableView?.estimatedRowHeight = estimatedRowHeight
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.separatorStyle = .none
        tableView?.keyboardDismissMode = .interactive
        tableView?.contentInsetAdjustmentBehavior = .automatic
    }
    
    @MainActor
    private func setupBindings() {
        // Bind to messages
        viewModel?.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                self?.updateMessages(messages)
            }
            .store(in: &cancellables)
        
        // Bind to typing status
        viewModel?.$isTyping
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isTyping in
                self?.updateTypingIndicator(isTyping)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func scrollToBottom(animated: Bool = true) {
        guard let tableView = tableView,
              !messages.isEmpty else { return }
        
        let lastSection = numberOfSections(in: tableView) - 1
        let lastRow = self.tableView(tableView, numberOfRowsInSection: lastSection) - 1
        
        guard lastSection >= 0, lastRow >= 0 else { return }
        
        let indexPath = IndexPath(row: lastRow, section: lastSection)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    func isNearBottom(threshold: CGFloat = 100) -> Bool {
        guard let tableView = tableView else { return false }
        
        let contentHeight = tableView.contentSize.height
        let frameHeight = tableView.frame.height
        let offset = tableView.contentOffset.y
        
        return offset > contentHeight - frameHeight - threshold
    }
    
    func reloadData() {
        tableView?.reloadData()
    }
    
    // MARK: - Private Methods
    
    private func updateMessages(_ newMessages: [ChatMessage]) {
        let wasNearBottom = isNearBottom()
        let oldCount = messages.count
        
        messages = newMessages
        
        // Smart update strategy
        if oldCount == 0 {
            // Initial load
            tableView?.reloadData()
            scrollToBottom(animated: false)
        } else if newMessages.count > oldCount {
            // New messages added
            let newIndexPaths = (oldCount..<newMessages.count).map {
                IndexPath(row: $0, section: 0)
            }
            
            tableView?.beginUpdates()
            tableView?.insertRows(at: newIndexPaths, with: .fade)
            tableView?.endUpdates()
            
            if wasNearBottom {
                scrollToBottom(animated: true)
            }
        } else if newMessages.count == oldCount {
            // Status update only - reload specific cells
            var indexPathsToReload: [IndexPath] = []
            
            for (index, message) in newMessages.enumerated() {
                if index < messages.count && messages[index].status != message.status {
                    indexPathsToReload.append(IndexPath(row: index, section: 0))
                }
            }
            
            if !indexPathsToReload.isEmpty {
                tableView?.reloadRows(at: indexPathsToReload, with: .none)
            }
        } else {
            // Messages removed
            tableView?.reloadData()
        }
    }
    
    private func updateTypingIndicator(_ show: Bool) {
        guard isTyping != show else { return }
        
        let wasNearBottom = isNearBottom()
        isTyping = show
        
        let typingIndexPath = IndexPath(row: messages.count, section: 0)
        
        tableView?.beginUpdates()
        if show {
            tableView?.insertRows(at: [typingIndexPath], with: .fade)
        } else {
            tableView?.deleteRows(at: [typingIndexPath], with: .fade)
        }
        tableView?.endUpdates()
        
        if wasNearBottom && show {
            scrollToBottom(animated: true)
        }
    }
    
    private func groupMessagesByDate() -> [(Date, [ChatMessage])] {
        let calendar = Calendar.current
        var grouped: [(Date, [ChatMessage])] = []
        var currentDate: Date?
        var currentGroup: [ChatMessage] = []
        
        for message in messages {
            let messageDate = calendar.startOfDay(for: message.timestamp)
            
            if let current = currentDate, calendar.isDate(current, inSameDayAs: messageDate) {
                currentGroup.append(message)
            } else {
                if !currentGroup.isEmpty, let date = currentDate {
                    grouped.append((date, currentGroup))
                }
                currentDate = messageDate
                currentGroup = [message]
            }
        }
        
        if !currentGroup.isEmpty, let date = currentDate {
            grouped.append((date, currentGroup))
        }
        
        return grouped
    }
}

// MARK: - UITableViewDataSource

extension ChatTableViewHandler: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // Simplified for now, can be extended for date grouping
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count + (isTyping ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Check if this is the typing indicator row
        if indexPath.row == messages.count && isTyping {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatTypingIndicatorCell", for: indexPath) as! ChatTypingIndicatorCell
            cell.startAnimating()
            return cell
        }
        
        // Regular message cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
        let message = messages[indexPath.row]
        
        // Configure cell
        cell.configure(with: message)
        
        // Set delegate for interactions
        cell.delegate = self
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ChatTableViewHandler: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Don't handle typing indicator taps
        guard indexPath.row < messages.count else { return }
        
        let message = messages[indexPath.row]
        
        // Handle failed message retry
        if message.status == MessageStatus.failed {
            Task {
                await viewModel?.retryMessage(message.id)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        // Typing indicator has fixed height
        if indexPath.row == messages.count && isTyping {
            return typingIndicatorHeight
        }
        
        // Estimate based on message content length
        guard indexPath.row < messages.count else {
            return estimatedRowHeight
        }
        
        let message = messages[indexPath.row]
        let contentLength = message.content.count
        
        // Rough estimation based on content length
        if contentLength < 50 {
            return 60
        } else if contentLength < 200 {
            return 100
        } else if contentLength < 500 {
            return 150
        } else {
            return 200
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Mark message as read when displayed
        guard indexPath.row < messages.count else { return }
        
        let message = messages[indexPath.row]
        if !message.isUser && message.status != MessageStatus.read {
            // Update to read status after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.viewModel?.updateMessageStatus(message.id, to: MessageStatus.read)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.row < messages.count else { return nil }
        
        let message = messages[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            var actions: [UIAction] = []
            
            // Copy action
            let copyAction = UIAction(
                title: "Copy",
                image: UIImage(systemName: "doc.on.doc")
            ) { _ in
                UIPasteboard.general.string = message.content
            }
            actions.append(copyAction)
            
            // Retry action for failed messages
            if message.status == MessageStatus.failed {
                let retryAction = UIAction(
                    title: "Retry",
                    image: UIImage(systemName: "arrow.clockwise")
                ) { [weak self] _ in
                    Task {
                        await self?.viewModel?.retryMessage(message.id)
                    }
                }
                actions.append(retryAction)
            }
            
            // Delete action
            let deleteAction = UIAction(
                title: "Delete",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { [weak self] _ in
                Task {
                    await self?.viewModel?.deleteMessage(message.id)
                }
            }
            actions.append(deleteAction)
            
            return UIMenu(title: "", children: actions)
        }
    }
}

// MARK: - UITableViewDataSourcePrefetching

extension ChatTableViewHandler: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        // Prefetch avatars or media content if needed
        for indexPath in indexPaths {
            guard indexPath.row < messages.count else { continue }
            
            let message = messages[indexPath.row]
            
            // TODO: Implement prefetching for media content
            // For now, just log for future implementation
            print("📥 Prefetching row \(indexPath.row) for message: \(message.id)")
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        // Cancel any ongoing prefetch operations
        for indexPath in indexPaths {
            print("❌ Cancelling prefetch for row \(indexPath.row)")
        }
    }
}

// MARK: - ChatMessageCellDelegate

extension ChatTableViewHandler: ChatMessageCellDelegate {
    
    func chatMessageCell(_ cell: ChatMessageCell, didTapLink url: URL) {
        // Handle link taps
        navigationDelegate?.navigateToURL(url)
    }
    
    func chatMessageCell(_ cell: ChatMessageCell, didTapMention username: String) {
        // Handle mention taps
        navigationDelegate?.navigateToUser(username)
    }
    
    func chatMessageCell(_ cell: ChatMessageCell, didTapCodeBlock code: String) {
        // Handle code block taps
        navigationDelegate?.showCodePreview(code)
    }
    
    func chatMessageCell(_ cell: ChatMessageCell, didLongPress message: ChatMessage) {
        // Show context menu or additional options
        guard let indexPath = tableView?.indexPath(for: cell) else { return }
        
        // Trigger haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Show context menu
        tableView?.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }
}

// MARK: - Supporting Protocols

protocol ChatNavigationDelegate: AnyObject {
    func navigateToURL(_ url: URL)
    func navigateToUser(_ username: String)
    func showCodePreview(_ code: String)
}

protocol ChatMessageCellDelegate: AnyObject {
    func chatMessageCell(_ cell: ChatMessageCell, didTapLink url: URL)
    func chatMessageCell(_ cell: ChatMessageCell, didTapMention username: String)
    func chatMessageCell(_ cell: ChatMessageCell, didTapCodeBlock code: String)
    func chatMessageCell(_ cell: ChatMessageCell, didLongPress message: ChatMessage)
}

