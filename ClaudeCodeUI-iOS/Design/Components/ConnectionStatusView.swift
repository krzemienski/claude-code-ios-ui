import UIKit

/// Connection status states
enum ConnectionStatus {
    case connected
    case connecting
    case disconnected
    case reconnecting
    case error
    
    var color: UIColor {
        switch self {
        case .connected: return CyberpunkTheme.neonGreen
        case .connecting, .reconnecting: return CyberpunkTheme.neonYellow
        case .disconnected, .error: return CyberpunkTheme.neonPink
        }
    }
    
    var text: String {
        switch self {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .reconnecting: return "Reconnecting..."
        case .error: return "Connection Error"
        }
    }
    
    var icon: String {
        switch self {
        case .connected: return "wifi"
        case .connecting, .reconnecting: return "wifi.exclamationmark"
        case .disconnected: return "wifi.slash"
        case .error: return "exclamationmark.triangle"
        }
    }
}

/// A cyberpunk-themed connection status indicator
class ConnectionStatusView: UIView {
    
    // MARK: - Properties
    
    private let iconView = UIImageView()
    private let statusLabel = UILabel()
    private let pulseView = UIView()
    private var pulseAnimation: CABasicAnimation?
    
    private(set) var status: ConnectionStatus = .disconnected {
        didSet {
            updateStatus()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // Configure self
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        
        // Setup pulse view (behind icon)
        pulseView.backgroundColor = .clear
        pulseView.layer.cornerRadius = 12
        pulseView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pulseView)
        
        // Setup icon
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .white
        iconView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        
        // Setup status label
        statusLabel.font = .systemFont(ofSize: 12, weight: .medium)
        statusLabel.textColor = .white
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statusLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            pulseView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            pulseView.centerYAnchor.constraint(equalTo: centerYAnchor),
            pulseView.widthAnchor.constraint(equalToConstant: 24),
            pulseView.heightAnchor.constraint(equalToConstant: 24),
            
            iconView.centerXAnchor.constraint(equalTo: pulseView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: pulseView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            
            statusLabel.leadingAnchor.constraint(equalTo: pulseView.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            heightAnchor.constraint(equalToConstant: 32)
        ])
        
        // Initial status
        updateStatus()
    }
    
    // MARK: - Public Methods
    
    func setStatus(_ status: ConnectionStatus) {
        self.status = status
    }
    
    func showInNavigationBar(of viewController: UIViewController) {
        guard let navigationController = viewController.navigationController else { return }
        
        // Create container for right bar button
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 140, height: 32))
        containerView.addSubview(self)
        
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topAnchor.constraint(equalTo: containerView.topAnchor),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        let barButtonItem = UIBarButtonItem(customView: containerView)
        viewController.navigationItem.rightBarButtonItem = barButtonItem
    }
    
    // MARK: - Private Methods
    
    private func updateStatus() {
        // Update icon and label
        iconView.image = UIImage(systemName: status.icon)
        statusLabel.text = status.text
        
        // Update colors with animation
        UIView.animate(withDuration: 0.3) {
            self.iconView.tintColor = self.status.color
            self.statusLabel.textColor = self.status.color
            self.layer.borderColor = self.status.color.withAlphaComponent(0.3).cgColor
            self.pulseView.backgroundColor = self.status.color.withAlphaComponent(0.2)
        }
        
        // Update animations
        updateAnimations()
    }
    
    private func updateAnimations() {
        // Remove existing animations
        pulseView.layer.removeAllAnimations()
        
        switch status {
        case .connected:
            // Subtle glow
            addGlowAnimation(intensity: 0.3)
            
        case .connecting, .reconnecting:
            // Pulsing animation
            addPulseAnimation()
            
        case .disconnected:
            // No animation
            break
            
        case .error:
            // Fast pulse
            addPulseAnimation(duration: 0.5)
        }
    }
    
    private func addPulseAnimation(duration: TimeInterval = 1.0) {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.2
        pulseAnimation.duration = duration
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseView.layer.add(pulseAnimation, forKey: "pulse")
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.3
        opacityAnimation.duration = duration
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity
        pulseView.layer.add(opacityAnimation, forKey: "opacity")
    }
    
    private func addGlowAnimation(intensity: Float = 0.5) {
        let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        glowAnimation.fromValue = 0
        glowAnimation.toValue = intensity
        glowAnimation.duration = 2.0
        glowAnimation.autoreverses = true
        glowAnimation.repeatCount = .infinity
        
        layer.shadowColor = status.color.cgColor
        layer.shadowRadius = 8
        layer.shadowOffset = .zero
        layer.add(glowAnimation, forKey: "glow")
    }
}

// MARK: - ConnectionStatusManager

class ConnectionStatusManager {
    static let shared = ConnectionStatusManager()
    
    private var statusViews: [ConnectionStatusView] = []
    
    private init() {
        // Listen for WebSocket notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWebSocketConnected),
            name: NSNotification.Name("WebSocketConnected"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWebSocketDisconnected),
            name: NSNotification.Name("WebSocketDisconnected"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWebSocketReconnecting),
            name: NSNotification.Name("WebSocketReconnecting"),
            object: nil
        )
    }
    
    func registerStatusView(_ statusView: ConnectionStatusView) {
        statusViews.append(statusView)
    }
    
    func unregisterStatusView(_ statusView: ConnectionStatusView) {
        statusViews.removeAll { $0 === statusView }
    }
    
    @objc private func handleWebSocketConnected() {
        updateAllStatusViews(.connected)
    }
    
    @objc private func handleWebSocketDisconnected() {
        updateAllStatusViews(.disconnected)
    }
    
    @objc private func handleWebSocketReconnecting() {
        updateAllStatusViews(.reconnecting)
    }
    
    private func updateAllStatusViews(_ status: ConnectionStatus) {
        DispatchQueue.main.async {
            self.statusViews.forEach { $0.setStatus(status) }
        }
    }
}