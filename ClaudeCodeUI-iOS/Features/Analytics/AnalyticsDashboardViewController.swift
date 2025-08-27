//
//  AnalyticsDashboardViewController.swift
//  ClaudeCodeUI
//
//  Created by Claude Code on 2025-01-21.
//

import UIKit

/// Dashboard showing user's own analytics data
class AnalyticsDashboardViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Usage cards
    private let sessionCard = AnalyticsCardView()
    private let projectsCard = AnalyticsCardView()
    private let messagesCard = AnalyticsCardView()
    private let filesCard = AnalyticsCardView()
    
    // Activity chart
    private let activityChartView = ActivityChartView()
    
    // Most used features
    private let featuresTableView = UITableView()
    private var topFeatures: [(name: String, count: Int)] = []
    
    // Privacy controls
    private let privacySection = UIView()
    private let privacyToggle = UISwitch()
    private let clearDataButton = UIButton()
    
    // MARK: - Properties
    
    private var analyticsData: AnalyticsData?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAnalyticsData()
        
        // Track screen view
        AnalyticsManager.shared.startScreenTracking("AnalyticsDashboard")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AnalyticsManager.shared.endScreenTracking("AnalyticsDashboard")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        title = "Analytics Dashboard"
        
        // Add close button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Title section
        titleLabel.text = "Your Usage Analytics"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = CyberpunkTheme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        subtitleLabel.text = "Privacy-first analytics. Data stored locally on your device."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = CyberpunkTheme.textTertiary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Setup cards
        setupCards()
        
        // Setup activity chart
        activityChartView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(activityChartView)
        
        // Setup features table
        setupFeaturesTable()
        
        // Setup privacy section
        setupPrivacySection()
        
        // Setup constraints
        setupConstraints()
        
        // Add animations
        AnimationManager.shared.fadeIn(titleLabel, duration: 0.3)
        AnimationManager.shared.fadeIn(subtitleLabel, duration: 0.3)
    }
    
    private func setupCards() {
        // Configure session card
        sessionCard.configure(
            title: "Sessions",
            value: "0",
            icon: UIImage(systemName: "bubble.left.and.bubble.right.fill"),
            color: CyberpunkTheme.primaryCyan
        )
        sessionCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sessionCard)
        
        // Configure projects card
        projectsCard.configure(
            title: "Projects",
            value: "0",
            icon: UIImage(systemName: "folder.fill"),
            color: CyberpunkTheme.primaryCyan
        )
        projectsCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(projectsCard)
        
        // Configure messages card
        messagesCard.configure(
            title: "Messages",
            value: "0",
            icon: UIImage(systemName: "message.fill"),
            color: CyberpunkTheme.success
        )
        messagesCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(messagesCard)
        
        // Configure files card
        filesCard.configure(
            title: "Files",
            value: "0",
            icon: UIImage(systemName: "doc.fill"),
            color: CyberpunkTheme.warning
        )
        filesCard.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(filesCard)
    }
    
    private func setupFeaturesTable() {
        let headerLabel = UILabel()
        headerLabel.text = "Most Used Features"
        headerLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        headerLabel.textColor = CyberpunkTheme.textPrimary
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerLabel)
        
        featuresTableView.backgroundColor = .clear
        featuresTableView.separatorStyle = .none
        featuresTableView.isScrollEnabled = false
        featuresTableView.delegate = self
        featuresTableView.dataSource = self
        featuresTableView.register(FeatureCell.self, forCellReuseIdentifier: "FeatureCell")
        featuresTableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(featuresTableView)
        
        // Store header reference
        featuresTableView.tag = 100 // Use tag to identify header
    }
    
    private func setupPrivacySection() {
        privacySection.backgroundColor = CyberpunkTheme.surface
        privacySection.layer.cornerRadius = 12
        privacySection.layer.borderWidth = 1
        privacySection.layer.borderColor = CyberpunkTheme.border.cgColor
        privacySection.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(privacySection)
        
        let privacyLabel = UILabel()
        privacyLabel.text = "Privacy Settings"
        privacyLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        privacyLabel.textColor = CyberpunkTheme.textPrimary
        privacyLabel.translatesAutoresizingMaskIntoConstraints = false
        privacySection.addSubview(privacyLabel)
        
        let toggleLabel = UILabel()
        toggleLabel.text = "Enable Analytics"
        toggleLabel.font = .systemFont(ofSize: 16)
        toggleLabel.textColor = CyberpunkTheme.textSecondary
        toggleLabel.translatesAutoresizingMaskIntoConstraints = false
        privacySection.addSubview(toggleLabel)
        
        privacyToggle.isOn = UserDefaults.standard.bool(forKey: "AnalyticsEnabled")
        privacyToggle.onTintColor = CyberpunkTheme.primaryCyan
        privacyToggle.addTarget(self, action: #selector(privacyToggleChanged), for: .valueChanged)
        privacyToggle.translatesAutoresizingMaskIntoConstraints = false
        privacySection.addSubview(privacyToggle)
        
        clearDataButton.setTitle("Clear Analytics Data", for: .normal)
        clearDataButton.setTitleColor(CyberpunkTheme.error, for: .normal)
        clearDataButton.titleLabel?.font = .systemFont(ofSize: 16)
        clearDataButton.addTarget(self, action: #selector(clearDataTapped), for: .touchUpInside)
        clearDataButton.translatesAutoresizingMaskIntoConstraints = false
        privacySection.addSubview(clearDataButton)
        
        // Privacy section constraints
        NSLayoutConstraint.activate([
            privacyLabel.topAnchor.constraint(equalTo: privacySection.topAnchor, constant: 16),
            privacyLabel.leadingAnchor.constraint(equalTo: privacySection.leadingAnchor, constant: 16),
            
            toggleLabel.topAnchor.constraint(equalTo: privacyLabel.bottomAnchor, constant: 16),
            toggleLabel.leadingAnchor.constraint(equalTo: privacySection.leadingAnchor, constant: 16),
            
            privacyToggle.centerYAnchor.constraint(equalTo: toggleLabel.centerYAnchor),
            privacyToggle.trailingAnchor.constraint(equalTo: privacySection.trailingAnchor, constant: -16),
            
            clearDataButton.topAnchor.constraint(equalTo: toggleLabel.bottomAnchor, constant: 16),
            clearDataButton.centerXAnchor.constraint(equalTo: privacySection.centerXAnchor),
            clearDataButton.bottomAnchor.constraint(equalTo: privacySection.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title section
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Cards - First row
            sessionCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            sessionCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sessionCard.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.43, constant: -25),
            sessionCard.heightAnchor.constraint(equalToConstant: 100),
            
            projectsCard.topAnchor.constraint(equalTo: sessionCard.topAnchor),
            projectsCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            projectsCard.widthAnchor.constraint(equalTo: sessionCard.widthAnchor),
            projectsCard.heightAnchor.constraint(equalToConstant: 100),
            
            // Cards - Second row
            messagesCard.topAnchor.constraint(equalTo: sessionCard.bottomAnchor, constant: 16),
            messagesCard.leadingAnchor.constraint(equalTo: sessionCard.leadingAnchor),
            messagesCard.widthAnchor.constraint(equalTo: sessionCard.widthAnchor),
            messagesCard.heightAnchor.constraint(equalToConstant: 100),
            
            filesCard.topAnchor.constraint(equalTo: messagesCard.topAnchor),
            filesCard.trailingAnchor.constraint(equalTo: projectsCard.trailingAnchor),
            filesCard.widthAnchor.constraint(equalTo: sessionCard.widthAnchor),
            filesCard.heightAnchor.constraint(equalToConstant: 100),
            
            // Activity chart
            activityChartView.topAnchor.constraint(equalTo: messagesCard.bottomAnchor, constant: 24),
            activityChartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            activityChartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            activityChartView.heightAnchor.constraint(equalToConstant: 200),
            
            // Features table
            featuresTableView.topAnchor.constraint(equalTo: activityChartView.bottomAnchor, constant: 24),
            featuresTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            featuresTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            featuresTableView.heightAnchor.constraint(equalToConstant: 200),
            
            // Privacy section
            privacySection.topAnchor.constraint(equalTo: featuresTableView.bottomAnchor, constant: 24),
            privacySection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            privacySection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            privacySection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Data Loading
    
    private func loadAnalyticsData() {
        // Load analytics data from local storage
        // This is placeholder - in production, load from the LocalAnalyticsProvider
        
        // Simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateUI(with: self?.generateMockData() ?? AnalyticsData())
        }
    }
    
    private func generateMockData() -> AnalyticsData {
        return AnalyticsData(
            totalSessions: 42,
            totalProjects: 8,
            totalMessages: 156,
            totalFiles: 234,
            activityData: [
                ("Mon", 12),
                ("Tue", 18),
                ("Wed", 25),
                ("Thu", 20),
                ("Fri", 30),
                ("Sat", 8),
                ("Sun", 5)
            ],
            topFeatures: [
                ("Chat", 156),
                ("File Explorer", 89),
                ("Terminal", 67),
                ("Search", 45),
                ("Git", 32)
            ]
        )
    }
    
    private func updateUI(with data: AnalyticsData) {
        analyticsData = data
        
        // Update cards with animation
        sessionCard.updateValue("\(data.totalSessions)")
        AnimationManager.shared.pulse(sessionCard, scale: 1.05)
        
        projectsCard.updateValue("\(data.totalProjects)")
        AnimationManager.shared.pulse(projectsCard, scale: 1.05)
        
        messagesCard.updateValue("\(data.totalMessages)")
        AnimationManager.shared.pulse(messagesCard, scale: 1.05)
        
        filesCard.updateValue("\(data.totalFiles)")
        AnimationManager.shared.pulse(filesCard, scale: 1.05)
        
        // Update activity chart
        activityChartView.updateData(data.activityData)
        
        // Update features table
        topFeatures = data.topFeatures
        featuresTableView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
        
        // Track action
        AnalyticsManager.shared.track(.buttonTapped(name: "CloseDashboard", screen: "AnalyticsDashboard"))
    }
    
    @objc private func privacyToggleChanged() {
        let isEnabled = privacyToggle.isOn
        UserDefaults.standard.set(isEnabled, forKey: "AnalyticsEnabled")
        
        // Track setting change
        AnalyticsManager.shared.track(.settingChanged(
            key: "AnalyticsEnabled",
            oldValue: !isEnabled,
            newValue: isEnabled
        ))
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    @objc private func clearDataTapped() {
        let alert = UIAlertController(
            title: "Clear Analytics Data",
            message: "This will permanently delete all local analytics data. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.clearAnalyticsData()
        })
        
        present(alert, animated: true)
    }
    
    private func clearAnalyticsData() {
        // Clear analytics
        AnalyticsManager.shared.reset()
        
        // Reset UI
        updateUI(with: AnalyticsData())
        
        // Show confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show temporary message
        showMessage("Analytics data cleared")
    }
    
    private func showMessage(_ message: String) {
        let messageView = UIView()
        messageView.backgroundColor = CyberpunkTheme.surface
        messageView.layer.cornerRadius = 8
        messageView.layer.borderWidth = 1
        messageView.layer.borderColor = CyberpunkTheme.primaryCyan.cgColor
        messageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = message
        label.textColor = CyberpunkTheme.primaryCyan
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        messageView.addSubview(label)
        
        view.addSubview(messageView)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: messageView.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: messageView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: messageView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: messageView.bottomAnchor, constant: -12),
            
            messageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        // Animate in
        messageView.alpha = 0
        messageView.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: 0.3, animations: {
            messageView.alpha = 1
            messageView.transform = .identity
        }) { _ in
            // Animate out after delay
            UIView.animate(withDuration: 0.3, delay: 2.0, options: [], animations: {
                messageView.alpha = 0
                messageView.transform = CGAffineTransform(translationX: 0, y: 20)
            }) { _ in
                messageView.removeFromSuperview()
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension AnalyticsDashboardViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topFeatures.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeatureCell", for: indexPath) as! FeatureCell
        let feature = topFeatures[indexPath.row]
        cell.configure(name: feature.name, count: feature.count, rank: indexPath.row + 1)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AnalyticsDashboardViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

// MARK: - Analytics Card View

private class AnalyticsCardView: UIView {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = CyberpunkTheme.surface
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = CyberpunkTheme.border.cgColor
        
        // Add subtle glow
        layer.shadowColor = CyberpunkTheme.primaryCyan.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = .zero
        layer.shadowRadius = 8
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        
        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = CyberpunkTheme.textTertiary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
        valueLabel.textColor = CyberpunkTheme.textPrimary
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            
            valueLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        ])
    }
    
    func configure(title: String, value: String, icon: UIImage?, color: UIColor) {
        titleLabel.text = title
        valueLabel.text = value
        iconImageView.image = icon?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = color
        layer.shadowColor = color.cgColor
    }
    
    func updateValue(_ value: String) {
        valueLabel.text = value
    }
}

// MARK: - Activity Chart View

private class ActivityChartView: UIView {
    private var bars: [UIView] = []
    private var labels: [UILabel] = []
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = CyberpunkTheme.surface
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = CyberpunkTheme.border.cgColor
        
        titleLabel.text = "Weekly Activity"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = CyberpunkTheme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        ])
    }
    
    func updateData(_ data: [(String, Int)]) {
        // Clear existing bars
        bars.forEach { $0.removeFromSuperview() }
        labels.forEach { $0.removeFromSuperview() }
        bars.removeAll()
        labels.removeAll()
        
        guard !data.isEmpty else { return }
        
        let maxValue = data.map { $0.1 }.max() ?? 1
        let barWidth = (bounds.width - 32 - CGFloat(data.count - 1) * 8) / CGFloat(data.count)
        let chartHeight: CGFloat = 120
        
        for (index, item) in data.enumerated() {
            // Create bar
            let barHeight = CGFloat(item.1) / CGFloat(maxValue) * chartHeight
            let bar = UIView()
            bar.backgroundColor = CyberpunkTheme.primaryCyan
            bar.layer.cornerRadius = 4
            bar.translatesAutoresizingMaskIntoConstraints = false
            addSubview(bar)
            bars.append(bar)
            
            // Create label
            let label = UILabel()
            label.text = item.0
            label.font = .systemFont(ofSize: 10)
            label.textColor = CyberpunkTheme.textTertiary
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            labels.append(label)
            
            // Add constraints
            NSLayoutConstraint.activate([
                bar.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -40),
                bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16 + CGFloat(index) * (barWidth + 8)),
                bar.widthAnchor.constraint(equalToConstant: barWidth),
                bar.heightAnchor.constraint(equalToConstant: barHeight),
                
                label.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 4),
                label.centerXAnchor.constraint(equalTo: bar.centerXAnchor),
                label.widthAnchor.constraint(equalToConstant: barWidth)
            ])
            
            // Animate bar entrance
            bar.transform = CGAffineTransform(scaleX: 1, y: 0)
            UIView.animate(withDuration: 0.5, delay: Double(index) * 0.05, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                bar.transform = .identity
            })
        }
    }
}

// MARK: - Feature Cell

private class FeatureCell: UITableViewCell {
    private let rankLabel = UILabel()
    private let nameLabel = UILabel()
    private let countLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        rankLabel.font = .systemFont(ofSize: 14, weight: .bold)
        rankLabel.textColor = CyberpunkTheme.primaryCyan
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rankLabel)
        
        nameLabel.font = .systemFont(ofSize: 14)
        nameLabel.textColor = CyberpunkTheme.textPrimary
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        countLabel.font = .systemFont(ofSize: 14)
        countLabel.textColor = CyberpunkTheme.textSecondary
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(countLabel)
        
        NSLayoutConstraint.activate([
            rankLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rankLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rankLabel.widthAnchor.constraint(equalToConstant: 30),
            
            nameLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            countLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            countLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(name: String, count: Int, rank: Int) {
        rankLabel.text = "#\(rank)"
        nameLabel.text = name
        countLabel.text = "\(count)"
        
        // Color top 3
        if rank <= 3 {
            rankLabel.textColor = rank == 1 ? CyberpunkTheme.warning : 
                                rank == 2 ? CyberpunkTheme.textSecondary : 
                                CyberpunkTheme.primaryCyan
        }
    }
}

// MARK: - Analytics Data Model

private struct AnalyticsData {
    var totalSessions: Int = 0
    var totalProjects: Int = 0
    var totalMessages: Int = 0
    var totalFiles: Int = 0
    var activityData: [(String, Int)] = []
    var topFeatures: [(name: String, count: Int)] = []
}