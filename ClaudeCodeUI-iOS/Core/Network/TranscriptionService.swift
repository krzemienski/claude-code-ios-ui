//
//  TranscriptionService.swift
//  ClaudeCodeUI
//
//  Transcription API service for audio to text conversion
//  REAL BACKEND - NO MOCKS
//

import Foundation
import AVFoundation
import Speech

// MARK: - Transcription Models

struct TranscriptionRequest: Codable {
    let audioData: Data
    let format: String // "wav", "m4a", "mp3"
    let language: String? // Optional language code
    let model: String? // Optional model selection
}

struct TranscriptionResponse: Codable {
    let text: String
    let confidence: Double?
    let language: String?
    let duration: Double?
    let segments: [TranscriptionSegment]?
}

struct TranscriptionSegment: Codable {
    let text: String
    let startTime: Double
    let endTime: Double
    let confidence: Double?
}

// MARK: - Transcription Service

final class TranscriptionService: NSObject {
    
    static let shared = TranscriptionService()
    
    private let apiClient = APIClient.shared
    private let baseURL = "http://localhost:3004"
    
    // Local speech recognition as fallback
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // Recording properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    
    override init() {
        super.init()
        requestSpeechAuthorization()
    }
    
    // MARK: - Authorization
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("✅ Speech recognition authorized")
                case .denied:
                    print("❌ Speech recognition denied")
                case .restricted:
                    print("⚠️ Speech recognition restricted")
                case .notDetermined:
                    print("❓ Speech recognition not determined")
                @unknown default:
                    print("Unknown speech recognition status")
                }
            }
        }
    }
    
    // MARK: - Recording
    
    func startRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Create recording URL
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            recordingURL = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            
            // Setup audio recorder
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            print("🎙️ Recording started at: \(recordingURL!.path)")
            completion(.success(recordingURL!))
            
        } catch {
            print("❌ Failed to start recording: \(error)")
            completion(.failure(error))
        }
    }
    
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        audioRecorder = nil
        
        print("🛑 Recording stopped")
        return recordingURL
    }
    
    // MARK: - Transcription via Backend
    
    func transcribeAudio(at url: URL) async throws -> TranscriptionResponse {
        print("📤 Sending audio to backend for transcription...")
        
        // Read audio file
        let audioData = try Data(contentsOf: url)
        
        // Create multipart form data request
        var request = URLRequest(url: URL(string: "\(baseURL)/api/transcribe")!)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart body
        var body = Data()
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add parameters
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"format\"\r\n\r\n".data(using: .utf8)!)
        body.append("m4a\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Add JWT token if available
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.invalidResponse
        }
        
        print("📥 Backend response: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 {
            let transcription = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
            print("✅ Transcription successful: \(transcription.text.prefix(100))...")
            return transcription
        } else {
            print("❌ Transcription failed with status: \(httpResponse.statusCode)")
            throw TranscriptionError.backendError(httpResponse.statusCode)
        }
    }
    
    // MARK: - Local Transcription (Fallback)
    
    func transcribeLocally(at url: URL) async throws -> String {
        print("📱 Using local speech recognition...")
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw TranscriptionError.recognizerNotAvailable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    // MARK: - Live Transcription
    
    func startLiveTranscription(onPartialResult: @escaping (String) -> Void,
                               onFinalResult: @escaping (String) -> Void,
                               onError: @escaping (Error) -> Void) {
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            onError(TranscriptionError.recognizerNotAvailable)
            return
        }
        
        do {
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Create recognition request
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                onError(TranscriptionError.recognitionRequestFailed)
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            // Setup audio engine
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            print("🎤 Live transcription started")
            
            // Start recognition
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { result, error in
                if let error = error {
                    onError(error)
                    self.stopLiveTranscription()
                } else if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    
                    if result.isFinal {
                        onFinalResult(transcription)
                        self.stopLiveTranscription()
                    } else {
                        onPartialResult(transcription)
                    }
                }
            }
            
        } catch {
            onError(error)
        }
    }
    
    func stopLiveTranscription() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        print("🛑 Live transcription stopped")
    }
    
    // MARK: - Hybrid Transcription
    
    func transcribeWithFallback(at url: URL) async throws -> String {
        do {
            // Try backend first
            let response = try await transcribeAudio(at: url)
            return response.text
        } catch {
            print("⚠️ Backend transcription failed, falling back to local: \(error)")
            // Fallback to local transcription
            return try await transcribeLocally(at: url)
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension TranscriptionService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Recording finished: \(flag ? "✅" : "❌")")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Recording error: \(error?.localizedDescription ?? "Unknown")")
    }
}

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case recognizerNotAvailable
    case recognitionRequestFailed
    case invalidResponse
    case backendError(Int)
    
    var errorDescription: String? {
        switch self {
        case .recognizerNotAvailable:
            return "Speech recognizer is not available"
        case .recognitionRequestFailed:
            return "Failed to create recognition request"
        case .invalidResponse:
            return "Invalid response from backend"
        case .backendError(let code):
            return "Backend error with status code: \(code)"
        }
    }
}

// MARK: - API Client Extension

extension APIClient {
    
    func transcribeAudio(_ data: Data, format: String = "m4a") async throws -> TranscriptionResponse {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/transcribe")!)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.\(format)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/\(format)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (responseData, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TranscriptionResponse.self, from: responseData)
    }
}