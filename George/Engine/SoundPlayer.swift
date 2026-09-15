import AppKit
import Foundation

@MainActor
final class SoundPlayer {
    private var playing: [NSSound] = []
    private var typingTask: Task<Void, Never>?
    private var isPlayingTyping = false
    private var nextTypingAt = Date()
    static let nextHumanAtDefault = Date().addingTimeInterval(Double.random(in: 90...180))
    private var nextHumanAt = SoundPlayer.nextHumanAtDefault

    func resetSchedule() {
        nextTypingAt = Date().addingTimeInterval(Double.random(in: 6...16))
        nextHumanAt = Date().addingTimeInterval(Double.random(in: 120...240))
    }

    func stopAll() {
        typingTask?.cancel()
        typingTask = nil
        isPlayingTyping = false
        playing.forEach { $0.stop() }
        playing.removeAll()
    }

    func playTypingBurst() {
        guard !isPlayingTyping else { return }
        let clips = urls(prefix: "typing-")
        guard let url = clips.randomElement() else { return }

        isPlayingTyping = true
        typingTask?.cancel()
        let duration = play(url: url)
        typingTask = Task { [weak self] in
            let nanos = UInt64(max(0.1, duration) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            if Task.isCancelled { return }
            self?.isPlayingTyping = false
        }
    }

    func tickAmbient() {
        let now = Date()
        if now >= nextTypingAt {
            playTypingBurst()
            nextTypingAt = now.addingTimeInterval(Double.random(in: 14...38))
        }
        if !isPlayingTyping, now >= nextHumanAt {
            playHuman()
            nextHumanAt = now.addingTimeInterval(Double.random(in: 120...480))
        }
    }

    private func playHuman() {
        let pool = urls(prefix: "hmm-") + urls(prefix: "throat-")
        guard let url = pool.randomElement() else { return }
        play(url: url)
    }

    @discardableResult
    private func play(url: URL) -> TimeInterval {
        guard let sound = NSSound(contentsOf: url, byReference: true) else { return 0 }
        sound.volume = url.lastPathComponent.hasPrefix("typing") ? 0.35 : 0.55
        playing.removeAll { !$0.isPlaying }
        playing.append(sound)
        sound.play()
        return sound.duration
    }

    private func urls(prefix: String) -> [URL] {
        guard let root = Bundle.main.resourceURL else { return [] }
        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        var matches: [URL] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension.lowercased() == "wav" else { continue }
            if url.lastPathComponent.lowercased().hasPrefix(prefix) {
                matches.append(url)
            }
        }
        return matches
    }
}
