//
//  TranscriptionViewController.swift
//  ClaudeCodeUI
//
//  Voice transcription UI with real-time feedback
//  NO MOCKS - REAL BACKEND INTEGRATION
//

import UIKit
import AVFoundation
import Speech

public class TranscriptionViewController: UIViewController {
    
    // MARK: - Properties
    
    private let transcriptionService = TranscriptionService.shared
    private var isRecording = false
    private var recordingURL: URL?
    private var transcribedText = ""
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Voice Transcription"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = CyberpunkTheme.primaryCyan
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap the microphone to start recording"
        label.font = .systemFont(ofSize: 16)
        label.textColor = CyberpunkTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let recordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "mic.circle.fill"), for: .normal)
        button.tintColor = CyberpunkTheme.primaryCyan
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()
    
    private let waveformView: WaveformView = {
        let view = WaveformView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()
    
    private let transcriptionTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = CyberpunkTheme.surface
        textView.textColor = CyberpunkTheme.primaryText
        textView.font = .systemFont(ofSize: 16)
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        textView.contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.isEditable = false
        return textView
    }()
    
    private let actionStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        return stack
    }()
    
    private let copyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Copy Text", for: .normal)
        button.setTitleColor(CyberpunkTheme.primaryCyan, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = CyberpunkTheme.surface
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = CyberpunkTheme.primaryCyan.withAlphaComponent(0.3).cgColor
        return button
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send to Chat", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = CyberpunkTheme.accentPink
        button.layer.cornerRadius = 8
        return button
    }()
    
    private let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear", for: .normal)
        button.setTitleColor(CyberpunkTheme.error, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = CyberpunkTheme.surface
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = CyberpunkTheme.error.withAlphaComponent(0.3).cgColor
        return button
    }()
    
    private let liveTranscriptionSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = CyberpunkTheme.primaryCyan
        return toggle
    }()
    
    private let liveTranscriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Live Transcription"
        label.font = .systemFont(ofSize: 14)
        label.textColor = CyberpunkTheme.secondaryText
        return label
    }()
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        requestPermissions()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = CyberpunkTheme.background
        
        // Add gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.black.cgColor,
            CyberpunkTheme.background.cgColor
        ]
        gradientLayer.locations = [0, 1]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Add components to content view
        [titleLabel, subtitleLabel, recordButton, waveformView,
         transcriptionTextView, actionStackView, liveTranscriptionLabel,
         liveTranscriptionSwitch].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        // Setup action stack
        [copyButton, sendButton, clearButton].forEach {
            actionStackView.addArrangedSubview($0)
        }
        
        // Setup constraints
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
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Record button
            recordButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            recordButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 120),
            recordButton.heightAnchor.constraint(equalToConstant: 120),
            
            // Waveform view
            waveformView.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20),
            waveformView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            waveformView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            waveformView.heightAnchor.constraint(equalToConstant: 60),
            
            // Live transcription toggle
            liveTranscriptionLabel.topAnchor.constraint(equalTo: waveformView.bottomAnchor, constant: 20),
            liveTranscriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            liveTranscriptionSwitch.centerYAnchor.constraint(equalTo: liveTranscriptionLabel.centerYAnchor),
            liveTranscriptionSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Transcription text view
            transcriptionTextView.topAnchor.constraint(equalTo: liveTranscriptionLabel.bottomAnchor, constant: 20),
            transcriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            transcriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            transcriptionTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            
            // Action stack
            actionStackView.topAnchor.constraint(equalTo: transcriptionTextView.bottomAnchor, constant: 20),
            actionStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            actionStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            actionStackView.heightAnchor.constraint(equalToConstant: 44),
            actionStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func setupActions() {
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyButtonTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        liveTranscriptionSwitch.addTarget(self, action: #selector(liveTranscriptionToggled), for: .valueChanged)
    }
    
    private func requestPermissions() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    self.showPermissionAlert()
                }
            }
        }
        
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { _ in }
    }
    
    // MARK: - Actions
    
    @objc private func recordButtonTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @objc private func copyButtonTapped() {
        UIPasteboard.general.string = transcribedText
        HapticFeedback.shared.impact(.light)
        
        // Show copied feedback
        let alert = UIAlertController(title: "Copied!", message: nil, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            alert.dismiss(animated: true)
        }
    }
    
    @objc private func sendButtonTapped() {
        guard !transcribedText.isEmpty else { return }
        
        // Send to chat via delegate or notification
        NotificationCenter.default.post(
            name: NSNotification.Name("TranscriptionToChat"),
            object: nil,
            userInfo: ["text": transcribedText]
        )
        
        HapticFeedback.shared.success()
        dismiss(animated: true)
    }
    
    @objc private func clearButtonTapped() {
        transcribedText = ""
        transcriptionTextView.text = ""
        HapticFeedback.shared.impact(.light)
    }
    
    @objc private func liveTranscriptionToggled() {
        // Handle live transcription toggle
        if liveTranscriptionSwitch.isOn {
            print("Live transcription enabled")
        } else {
            print("Live transcription disabled")
        }
    }
    
    // MARK: - Recording
    
    private func startRecording() {
        HapticFeedback.shared.impact(.medium)
        
        if liveTranscriptionSwitch.isOn {
            startLiveTranscription()
        } else {
            startFileRecording()
        }
        
        isRecording = true
        updateRecordingUI()
    }
    
    private func stopRecording() {
        HapticFeedback.shared.impact(.medium)
        
        if liveTranscriptionSwitch.isOn {
            transcriptionService.stopLiveTranscription()
        } else {
            stopFileRecording()
        }
        
        isRecording = false
        updateRecordingUI()
    }
    
    private func startFileRecording() {
        transcriptionService.startRecording { [weak self] result in
            switch result {
            case .success(let url):
                self?.recordingURL = url
                self?.waveformView.startAnimating()
            case .failure(let error):
                self?.showError(error)
            }
        }
    }
    
    private func stopFileRecording() {
        guard let url = transcriptionService.stopRecording() else { return }
        
        waveformView.stopAnimating()
        transcribeRecording(at: url)
    }
    
    private func startLiveTranscription() {
        waveformView.startAnimating()
        transcriptionTextView.text = ""
        
        transcriptionService.startLiveTranscription(
            onPartialResult: { [weak self] text in
                DispatchQueue.main.async {
                    self?.transcriptionTextView.text = text
                    self?.transcribedText = text
                }
            },
            onFinalResult: { [weak self] text in
                DispatchQueue.main.async {
                    self?.transcriptionTextView.text = text
                    self?.transcribedText = text
                    HapticFeedback.shared.success()
                }
            },
            onError: { [weak self] error in
                DispatchQueue.main.async {
                    self?.showError(error)
                }
            }
        )
    }
    
    private func transcribeRecording(at url: URL) {
        subtitleLabel.text = "Transcribing..."
        
        Task {
            do {
                let text = try await transcriptionService.transcribeWithFallback(at: url)
                
                await MainActor.run {
                    self.transcribedText = text
                    self.transcriptionTextView.text = text
                    self.subtitleLabel.text = "Transcription complete!"
                    HapticFeedback.shared.success()
                }
            } catch {
                await MainActor.run {
                    self.showError(error)
                }
            }
        }
    }
    
    // MARK: - UI Updates
    
    private func updateRecordingUI() {
        UIView.animate(withDuration: 0.3) {
            if self.isRecording {
                self.recordButton.tintColor = CyberpunkTheme.error
                self.recordButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.subtitleLabel.text = "Recording... Tap to stop"
                self.waveformView.isHidden = false
            } else {
                self.recordButton.tintColor = CyberpunkTheme.primaryCyan
                self.recordButton.transform = .identity
                self.subtitleLabel.text = "Tap the microphone to start recording"
                self.waveformView.isHidden = true
            }
        }
        
        // Add glow effect when recording
        if isRecording {
            addRecordingGlow()
        } else {
            removeRecordingGlow()
        }
    }
    
    private func addRecordingGlow() {
        let glowLayer = CALayer()
        glowLayer.name = "recordingGlow"
        glowLayer.frame = recordButton.bounds
        glowLayer.cornerRadius = 60
        glowLayer.backgroundColor = CyberpunkTheme.error.cgColor
        glowLayer.shadowColor = CyberpunkTheme.error.cgColor
        glowLayer.shadowRadius = 20
        glowLayer.shadowOpacity = 0.8
        glowLayer.shadowOffset = .zero
        
        recordButton.layer.insertSublayer(glowLayer, at: 0)
        
        // Pulse animation
        let pulse = CABasicAnimation(keyPath: "shadowRadius")
        pulse.fromValue = 20
        pulse.toValue = 30
        pulse.duration = 1
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        
        glowLayer.add(pulse, forKey: "pulse")
    }
    
    private func removeRecordingGlow() {
        recordButton.layer.sublayers?.first { $0.name == "recordingGlow" }?.removeFromSuperlayer()
    }
    
    // MARK: - Error Handling
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Microphone Permission Required",
            message: "Please enable microphone access in Settings to use voice transcription.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Transcription Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
        
        subtitleLabel.text = "Error occurred. Please try again."
        HapticFeedback.shared.error()
    }
}

// MARK: - Waveform View

class WaveformView: UIView {
    
    private var bars: [UIView] = []
    private let numberOfBars = 20
    private var displayLink: CADisplayLink?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBars()
    }
    
    private func setupBars() {
        for _ in 0..<numberOfBars {
            let bar = UIView()
            bar.backgroundColor = CyberpunkTheme.primaryCyan
            bar.layer.cornerRadius = 2
            bars.append(bar)
            addSubview(bar)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let barWidth = bounds.width / CGFloat(numberOfBars * 2 - 1)
        let spacing = barWidth
        
        for (index, bar) in bars.enumerated() {
            let x = CGFloat(index) * (barWidth + spacing)
            bar.frame = CGRect(x: x, y: bounds.height / 2, width: barWidth, height: 4)
        }
    }
    
    func startAnimating() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateWaveform))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stopAnimating() {
        displayLink?.invalidate()
        displayLink = nil
        
        // Reset bars
        bars.forEach { bar in
            UIView.animate(withDuration: 0.3) {
                bar.transform = .identity
            }
        }
    }
    
    @objc private func updateWaveform() {
        for (index, bar) in bars.enumerated() {
            let phase = CFAbsoluteTimeGetCurrent() * 2 + Double(index) * 0.2
            let height = (sin(phase) + 1) * 0.5 * bounds.height * 0.8 + 4
            
            UIView.animate(withDuration: 0.1) {
                bar.transform = CGAffineTransform(scaleX: 1, y: height / 4)
            }
        }
    }
}