import AVFoundation
import Speech
import Combine
import UIKit

@MainActor
class VoiceCaptureService: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var waveformLevels: [CGFloat] = Array(repeating: 0.05, count: 28)
    @Published var transcription = ""
    @Published var isTranscribing = false
    @Published var currentLevel: Float = 0.0

    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recordingStartTime: Date?
    private var waveformTimer: Timer?
    private var speechRecognizer: SFSpeechRecognizer?
    private let audioSession = AVAudioSession.sharedInstance()

    private let waveformBarCount = 28

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func startRecording() throws {
        guard !isRecording else { return }

        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true)

        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { return }

        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let crispDir = documentsDir.appendingPathComponent("Crisp", isDirectory: true)
        try? FileManager.default.createDirectory(at: crispDir, withIntermediateDirectories: true)

        let fileName = "capture_\(UUID().uuidString).m4a"
        recordingURL = crispDir.appendingPathComponent(fileName)

        guard let recordingURL = recordingURL else { return }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioFile = try AVAudioFile(forWriting: recordingURL, settings: settings)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }

            do {
                try self.audioFile?.write(from: buffer)
            } catch {
                // silently ignore write errors
            }

            self.recognitionRequest?.append(buffer)

            let level = self.calculateLevel(from: buffer)
            Task { @MainActor in
                self.currentLevel = level
                self.updateWaveform(level: level)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()

        recordingStartTime = Date()
        isRecording = true
        transcription = ""
        startWaveformAnimation()
    }

    func stopRecording() -> URL? {
        guard isRecording else { return nil }

        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        recognitionRequest?.endAudio()

        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        isRecording = false
        stopWaveformAnimation()

        audioFile = nil

        try? audioSession.setActive(false)

        return recordingURL
    }

    private func calculateLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: 1).map { channelDataValue[$0] }

        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        let level = max(0, min(1, (avgPower + 50) / 50))
        return level
    }

    private func updateWaveform(level: Float) {
        var newLevels = waveformLevels
        newLevels.removeFirst()
        newLevels.append(CGFloat(level))
        waveformLevels = newLevels
    }

    private func startWaveformAnimation() {
        waveformTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if self.isRecording && self.currentLevel < 0.01 {
                    self.updateWaveform(level: Float.random(in: 0.02...0.08))
                }
            }
        }
    }

    private func stopWaveformAnimation() {
        waveformTimer?.invalidate()
        waveformTimer = nil
        waveformLevels = Array(repeating: 0.05, count: waveformBarCount)
    }

    nonisolated func transcribe(audioURL: URL) async -> String {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer, recognizer.isAvailable else {
            return ""
        }

        return await withCheckedContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false
            request.requiresOnDeviceRecognition = false

            let task = recognizer.recognitionTask(with: request) { result, error in
                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                } else if error != nil {
                    continuation.resume(returning: "")
                }
            }

            _ = task
        }
    }
}
