import AppKit
import Foundation
import CoreGraphics

enum MovementMode: String, Codable, CaseIterable, Identifiable {
    case interval
    case random

    var id: String { rawValue }

    var title: String {
        switch self {
        case .interval: return "Every X seconds"
        case .random: return "Full random"
        }
    }

    var shortTitle: String {
        switch self {
        case .interval: return "Steady"
        case .random: return "Random"
        }
    }

    var subtitle: String {
        switch self {
        case .interval: return "Move on a steady cadence"
        case .random: return "Wait a random interval, then wander"
        }
    }
}

enum SelectionOrder: String, Codable, CaseIterable, Identifiable {
    case sequential
    case random

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sequential: return "In order"
        case .random: return "Random"
        }
    }
}

enum RunState: String {
    case off
    case waiting
    case running

    var menuTitle: String {
        switch self {
        case .off: return "Off"
        case .waiting: return "Armed — waiting for idle"
        case .running: return "Running"
        }
    }
}

struct ClickTarget: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var x: Double
    var y: Double
    var clickCount: Int
    var enabled: Bool
    var hasPosition: Bool

    var point: CGPoint { CGPoint(x: x, y: y) }

    static func make(index: Int) -> ClickTarget {
        ClickTarget(
            id: UUID(),
            name: "Click \(index)",
            x: 0,
            y: 0,
            clickCount: 1,
            enabled: true,
            hasPosition: false
        )
    }
}

struct TextAction: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var x: Double
    var y: Double
    var hasPosition: Bool
    var phrasesText: String
    var phraseOrder: SelectionOrder
    var pressEnter: Bool
    var enabled: Bool
    var nextPhraseIndex: Int

    var point: CGPoint { CGPoint(x: x, y: y) }

    var phrases: [String] {
        phrasesText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var isReady: Bool {
        enabled && hasPosition && !phrases.isEmpty
    }

    mutating func takePhrase() -> String? {
        let list = phrases
        guard !list.isEmpty else { return nil }
        switch phraseOrder {
        case .random:
            return list.randomElement()
        case .sequential:
            let phrase = list[nextPhraseIndex % list.count]
            nextPhraseIndex = (nextPhraseIndex + 1) % list.count
            return phrase
        }
    }

    static func make(index: Int) -> TextAction {
        TextAction(
            id: UUID(),
            name: "Text \(index)",
            x: 0,
            y: 0,
            hasPosition: false,
            phrasesText: "",
            phraseOrder: .sequential,
            pressEnter: true,
            enabled: true,
            nextPhraseIndex: 0
        )
    }
}

enum GeorgeBrand {
    static let name = "George Is Looking Busy"
    static let tagline = "He looks very busy."
    static let subtitle = "The Activity Simulator"
    static let bundleID = "com.lookbusy.george"
    static let disclaimer = """
    George is provided as-is, with no warranty of any kind. Nothing is guaranteed: not that it works, not that it is fit for any purpose, and not that using it is allowed where you use it. You use it entirely at your own risk. The authors are not liable for anything that happens.
    """

    static var licenseText: String {
        if let url = Bundle.main.url(forResource: "LICENSE", withExtension: "txt"),
           let text = try? String(contentsOf: url, encoding: .utf8),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        return fallbackLicense
    }

    private static let fallbackLicense = """
    MIT License

    Copyright (c) 2026 Oliver Maerz

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    """

    static func appIcon() -> NSImage {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        if let image = NSImage(named: "AppIcon") {
            return image
        }
        return NSApp.applicationIconImage
    }
}
