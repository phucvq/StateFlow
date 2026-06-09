import Foundation
import AVFoundation

@Observable
final class AudioService {

    // MARK: - State
    private(set) var currentSoundscapeId: String = "none"
    private(set) var isPlaying: Bool = false
    var volume: Float = 0.6 {
        didSet { audioPlayer?.volume = volume }
    }

    // MARK: - Private
    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?

    // MARK: - Init
    init() {
        currentSoundscapeId = UserPreferences.shared.selectedSoundscapeId
        volume = UserPreferences.shared.soundscapeVolume
        configureAudioSession()
    }

    // MARK: - Audio Session
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioService: Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Play
    func play(soundscapeId: String, fadeIn: Bool = true) {
        guard soundscapeId != "none" else {
            currentSoundscapeId = "none"
            UserPreferences.shared.selectedSoundscapeId = "none"
            stop(fadeOut: false)
            return
        }

        // If already playing this soundscape, just ensure it's running
        if currentSoundscapeId == soundscapeId && isPlaying {
            return
        }

        stop(fadeOut: false)
        currentSoundscapeId = soundscapeId
        UserPreferences.shared.selectedSoundscapeId = soundscapeId

        // Try to find audio file in bundle
        guard let soundscape = Soundscape.find(id: soundscapeId),
              let filename = soundscape.filename else { return }

        // Look for audio file (mp3 or m4a)
        let extensions = ["mp3", "m4a", "wav", "aac"]
        var url: URL?
        for ext in extensions {
            if let bundleURL = Bundle.main.url(forResource: filename, withExtension: ext) {
                url = bundleURL
                break
            }
        }

        // If no real audio file found, we'll just track state
        // (in production, audio files would be bundled)
        guard let audioURL = url else {
            // Simulate playing for development/simulator
            isPlaying = true
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.numberOfLoops = -1 // Loop infinitely
            audioPlayer?.volume = fadeIn ? 0 : volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true

            if fadeIn {
                self.fadeIn(to: volume, duration: 2.0)
            }
        } catch {
            print("AudioService: Failed to play \(filename): \(error)")
            isPlaying = true // Still mark as "playing" for UI state
        }
    }

    // MARK: - Stop
    func stop(fadeOut: Bool = true) {
        if fadeOut && isPlaying {
            self.fadeOut(duration: 3.0) { [weak self] in
                self?.audioPlayer?.stop()
                self?.audioPlayer = nil
                self?.isPlaying = false
            }
        } else {
            audioPlayer?.stop()
            audioPlayer = nil
            isPlaying = false
        }
    }

    // MARK: - Fade In
    private func fadeIn(to targetVolume: Float, duration: TimeInterval) {
        fadeTimer?.invalidate()
        let steps: Float = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = targetVolume / steps
        var currentStep: Float = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            currentStep += 1
            let newVolume = min(volumeStep * currentStep, targetVolume)
            self.audioPlayer?.volume = newVolume
            if currentStep >= steps {
                timer.invalidate()
            }
        }
    }

    // MARK: - Fade Out
    private func fadeOut(duration: TimeInterval, completion: @escaping () -> Void) {
        fadeTimer?.invalidate()
        let currentVol = audioPlayer?.volume ?? volume
        let steps: Float = 20
        let stepDuration = duration / Double(steps)
        let volumeStep = currentVol / steps
        var currentStep: Float = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            currentStep += 1
            let newVolume = max(currentVol - volumeStep * currentStep, 0)
            self.audioPlayer?.volume = newVolume
            if currentStep >= steps {
                timer.invalidate()
                completion()
            }
        }
    }

    // MARK: - Duck for Notifications
    func duck() {
        audioPlayer?.setVolume(volume * 0.2, fadeDuration: 0.5)
    }

    func unduck() {
        audioPlayer?.setVolume(volume, fadeDuration: 0.5)
    }
}
